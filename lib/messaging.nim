import
  terminal,
  strutils

import
  minimline

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

