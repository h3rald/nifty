import
  critbits,
  terminal

system.addQuitProc(resetAttributes)

when defined(windows):
   proc getchr*(): cint {.header: "<conio.h>", importc: "_getch".}
   proc putchr*(c: cint): cint {.discardable, header: "<conio.h>", importc: "_putch".}
else:
  proc putchr*(c: cint) =
    stdout.write(c.chr)

  proc getchr*(): cint =
    return getch().ord.cint

# Types

type
  Key* = int
  KeySeq* = seq[Key]
  KeyCallback* = proc(ed: var LineEditor)
  LineError* = ref Exception
  LineEditorError* = ref Exception
  Line = object
    text: string
    position: int
  LineEditor* = object
    line: Line

# Internal Methods

proc empty(line: Line): bool =
  return line.text.len <= 0

proc full(line: Line): bool =
  return line.position >= line.text.len

proc first(line: Line): int =
  if line.empty:
    raise LineError(msg: "Line is empty!")
  return 0

proc last(line: Line): int =
  if line.empty:
    raise LineError(msg: "Line is empty!")
  return line.text.len-1

proc fromStart(line: Line): string =
  if line.empty:
    return ""
  return line.text[line.first..line.position-1]

proc toEnd(line: Line): string =
  if line.empty:
    return ""
  return line.text[line.position..line.last]

proc back*(ed: var LineEditor, n=1) =
  if ed.line.position <= 0:
    return
  stdout.cursorBackward(n)
  ed.line.position = ed.line.position - n

proc forward*(ed: var LineEditor, n=1) = 
  if ed.line.full:
    return
  stdout.cursorForward(n)
  ed.line.position += n

# Public API

proc deletePrevious*(ed: var LineEditor) =
  if ed.line.position <= 0:
    return
  if not ed.line.empty:
    if ed.line.full:
      stdout.cursorBackward
      putchr(32)
      stdout.cursorBackward
      ed.line.position.dec
      ed.line.text = ed.line.text[0..ed.line.last-1]
    else:
      let rest = ed.line.toEnd & " "
      ed.back
      for i in rest:
        putchr i.ord.cint
      ed.line.text = ed.line.fromStart & ed.line.text[ed.line.position+1..ed.line.last]
      stdout.cursorBackward(rest.len)
  
proc deleteNext*(ed: var LineEditor) =
  if not ed.line.empty:
    if not ed.line.full:
      let rest = ed.line.toEnd[1..^1] & " "
      for c in rest:
        putchr c.ord.cint
      stdout.cursorBackward(rest.len)
      ed.line.text = ed.line.fromStart & ed.line.toEnd[1..^1]

proc printChar*(ed: var LineEditor, c: int) =  
  if ed.line.full:
    putchr(c.cint)
    ed.line.text &= c.chr
    ed.line.position += 1
  else:
    putchr(c.cint)
    let rest = ed.line.toEnd
    ed.line.text.insert($c.chr, ed.line.position)
    ed.line.position += 1
    for j in rest:
      putchr(j.ord.cint)
      ed.line.position += 1
    ed.back(rest.len)

proc print*(ed: var LineEditor, str: string) =
  for c in str:
    ed.printChar(c.ord)

# Character sets
const
  CTRL*        = {0 .. 31}
  DIGIT*       = {48 .. 57}
  LETTER*      = {65 .. 122}
  UPPERLETTER* = {65 .. 90}
  LOWERLETTER* = {97 .. 122}
  PRINTABLE*   = {32 .. 126}
when defined(windows):
  const
    ESCAPES* = {0, 22, 224}
else:
  const
    ESCAPES* = {27}


# Key Mappings
var KEYMAP*: CritBitTree[KeyCallBack]

KEYMAP["backspace"] = proc(ed: var LineEditor) =
  ed.deletePrevious()
KEYMAP["delete"] = proc(ed: var LineEditor) =
  ed.deleteNext()
KEYMAP["down"] = proc(ed: var LineEditor) =
  discard
KEYMAP["up"] = proc(ed: var LineEditor) =
  discard
KEYMAP["left"] = proc(ed: var LineEditor) =
  ed.back()
KEYMAP["right"] = proc(ed: var LineEditor) =
  ed.forward()
KEYMAP["ctrl+c"] = proc(ed: var LineEditor) =
  quit(0)
KEYMAP["ctrl+d"] = proc(ed: var LineEditor) =
  quit(0)

# Key Names
var KEYNAMES*: array[0..31, string]
KEYNAMES[1]    =    "ctrl+a"
KEYNAMES[2]    =    "ctrl+b"
KEYNAMES[3]    =    "ctrl+c"
KEYNAMES[4]    =    "ctrl+d"
KEYNAMES[5]    =    "ctrl+e"
KEYNAMES[6]    =    "ctrl+f"
KEYNAMES[7]    =    "ctrl+g"
KEYNAMES[8]    =    "ctrl+h"
KEYNAMES[9]    =    "ctrl+i"
KEYNAMES[9]    =    "tab"
KEYNAMES[10]   =    "ctrl+j"
KEYNAMES[11]   =    "ctrl+k"
KEYNAMES[12]   =    "ctrl+l"
KEYNAMES[13]   =    "ctrl+m"
KEYNAMES[14]   =    "ctrl+n"
KEYNAMES[15]   =    "ctrl+o"
KEYNAMES[16]   =    "ctrl+p"
KEYNAMES[17]   =    "ctrl+q"
KEYNAMES[18]   =    "ctrl+r"
KEYNAMES[19]   =    "ctrl+s"
KEYNAMES[20]   =    "ctrl+t"
KEYNAMES[21]   =    "ctrl+u"
KEYNAMES[22]   =    "ctrl+v"
KEYNAMES[23]   =    "ctrl+w"
KEYNAMES[24]   =    "ctrl+x"
KEYNAMES[25]   =    "ctrl+y"
KEYNAMES[26]   =    "ctrl+z"

# Key Sequences
var KEYSEQS*: CritBitTree[KeySeq]

when defined(windows):
  KEYSEQS["up"]         = @[224, 72]
  KEYSEQS["down"]       = @[224, 80]
  KEYSEQS["right"]      = @[224, 77]
  KEYSEQS["left"]       = @[224, 75]
  KEYSEQS["insert"]     = @[224, 82]
  KEYSEQS["delete"]     = @[224, 83]
else:
  KEYSEQS["up"]         = @[27, 91, 65]
  KEYSEQS["down"]       = @[27, 91, 66]
  KEYSEQS["right"]      = @[27, 91, 67]
  KEYSEQS["left"]       = @[27, 91, 68]
  KEYSEQS["home"]       = @[27, 91, 72]
  KEYSEQS["end"]        = @[27, 91, 70]
  KEYSEQS["insert"]     = @[27, 91, 50, 126]
  KEYSEQS["delete"]     = @[27, 91, 51, 126]

proc readLine*(ed: var LineEditor, prompt="", hidechars = false, reset = true): string =
  stdout.write(prompt)
  if reset:
    ed.line = Line(text: "", position: 0)
  var c = -1 # Used to manage completions
  var esc = false
  while true:
    var c1: int
    if c > 0:
      c1 = c
      c = -1
    else:
      c1 = getchr()
    if esc:
      esc = false
      continue
    elif c1 in {10, 13}:
      stdout.write("\n")
      return ed.line.text 
    elif c1 in {8, 127}:
      KEYMAP["backspace"](ed)
    elif c1 in PRINTABLE:
      if hidechars:
        putchr('*'.ord.cint)
        ed.line.text &= c1.chr
        ed.line.position.inc
      else:
        ed.printChar(c1)
    elif c1 in ESCAPES:
      var s = newSeq[Key](0)
      s.add(c1)
      let c2 = getchr()
      s.add(c2)
      if s == KEYSEQS["left"]:
        KEYMAP["left"](ed)
      elif s == KEYSEQS["right"]:
        KEYMAP["right"](ed)
      elif s == KEYSEQS["up"]:
        KEYMAP["up"](ed)
      elif s == KEYSEQS["down"]:
        KEYMAP["down"](ed)
      elif s == KEYSEQS["home"]:
        KEYMAP["home"](ed)
      elif s == KEYSEQS["end"]:
        KEYMAP["end"](ed)
      elif s == KEYSEQS["delete"]:
        KEYMAP["delete"](ed)
      elif s == KEYSEQS["insert"]:
        KEYMAP["insert"](ed)
      elif c2 == 91:
        let c3 = getchr()
        s.add(c3)
        if s == KEYSEQS["right"]:
          KEYMAP["right"](ed)
        elif s == KEYSEQS["left"]:
          KEYMAP["left"](ed)
        elif s == KEYSEQS["up"]:
          KEYMAP["up"](ed)
        elif s == KEYSEQS["down"]:
          KEYMAP["down"](ed)
        elif s == KEYSEQS["home"]:
          KEYMAP["home"](ed)
        elif s == KEYSEQS["end"]:
          KEYMAP["end"](ed)
        elif c3 in {50, 51}:
          let c4 = getchr()
          s.add(c4)
          if c4 == 126 and c3 == 50:
            KEYMAP["insert"](ed)
          elif c4 == 126 and c3 == 51:
            KEYMAP["delete"](ed)
    elif KEYMAP.hasKey(KEYNAMES[c1]):
      KEYMAP[KEYNAMES[c1]](ed)
    else:
      # Assuming unhandled two-values escape sequence; do nothing.
      if esc:
        esc = false
        continue
      else:
        esc = true
        continue

proc password*(ed: var LineEditor, prompt=""): string =
  return ed.readLine(prompt, true)

proc initEditor*(): LineEditor =
  result.line.text = ""
  result.line.position = 0

proc edit*(ed: var LineEditor, value: string): string =
  ed.print value
  return ed.readLine("", false, false)
