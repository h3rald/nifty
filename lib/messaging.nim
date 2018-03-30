import
  terminal,
  strutils,
  sequtils,
  unicode

import
  minimline

type
  TreeNode* = object
    label: string
    nodes: seq[TreeNode]

proc foreground(str: string, color: ForegroundColor) =
  stdout.setForegroundColor(color)
  stdout.write(str)
  resetAttributes()

proc printGreen*(str: string) =
  foreground(str, fgGreen)
  
proc printRed*(str: string) =
  foreground(str, fgRed)
  
proc printYellow*(str: string) =
  foreground(str, fgYellow)
  
proc printBlue*(str: string) =
  foreground(str, fgBlue)
  
proc confirm*(q: string): bool =
  printYellow("(!) " & q & " [y/n]: ")
  var ed = initEditor()
  let answer = ed.readLine().toLowerAscii[0]
  if answer == 'y':
    return true
  return false

proc printValue*(key, value: string) =
  printBlue("    -> $1: " % key)
  printGreen(value)
  resetAttributes()
  stdout.write("\n")

proc editValue*(key: string, value = ""): string =
  printBlue("    -> $1: " % key)
  var ed = initEditor()
  result = ed.edit(value)
  
proc printDeleted*(label, value: string) =
  printRed("--- ")
  echo label & ": " & value

proc printAdded*(label, value: string) =
  printGreen("+++ ")
  echo label & ": " & value

when defined(windows):
  proc ch(s): string =
    case s:
      of "└":
        return $(192.chr)
      of "├":
        return $(195.chr)
      of "─":
        return $(196.chr)
      of "┬":
        return $(194.chr)
      of "│":
        return $(179.chr)
else:
  proc ch(s: string): string = 
    return s

proc newTreeNode*(label: string): TreeNode =
  result.label = label
  result.nodes = newSeq[TreeNode]()

proc add*(x: var TreeNode, node: TreeNode) =
  x.nodes.add(node)

proc tree*(node: TreeNode, prefix = ""): string =
  let splitterPart = if node.nodes.len > 0: ch("│") else: ""
  let splitter = "\n" & prefix & splitterPart & ""
  return prefix & [node.label].join(splitter) & "\n" & node.nodes.map(proc(x: TreeNode): string =
    let ix = node.nodes.find(x)
    let last = node.nodes.len-1 == ix
    let more = x.nodes.len > 0
    let prefixPart = if last: " " else: ch("│")
    let newPrefix = prefix & prefixPart & " "
    let lastPart = if last: ch("└") else: ch("├")
    let morePart = if more: ch("┬") else: ch("─")
    let rec = tree(x, newPrefix)
    var offset = 3
    var endSpace = ""
    if lastPart == ch("└"):
      offset = 2
      endSpace = " "
    return prefix & lastPart & ch("─") & morePart & endSpace & rec[prefix.len+offset .. rec.len-1]
  ).join("")



