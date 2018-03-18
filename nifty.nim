import 
  json,
  os,
  ospaths,
  parseopt,
  logging,
  strutils,
  terminal,
  pegs,
  sequtils

import
  lib/niftylogger

newNiftyLogger().addHandler()
setLogFilter(lvlInfo)

import
  lib/config,
  lib/project

type
  NiftyOption = object
    key: string
    val: JsonNode

when defined(windows):
   proc putchr*(c: cint): cint {.discardable, header: "<conio.h>", importc: "_putch".}
else:
  proc putchr*(c: cint) =
    stdout.write(c.chr)

proc confirm(q: string): bool =
  stdout.setForegroundColor(fgYellow)
  stdout.write("(!) " & q & " [y/n]: ")
  resetAttributes()
  let answer = stdin.readLine
  if answer.match(peg"^ i'y' / i'yes' $"):
    return true
  return false

proc changeValue(oldv: tuple[label: string, value: JsonNode], newv: tuple[label: string, value: JsonNode]): bool =
  if oldv.value != newJNull():
    stdout.setForegroundColor(fgRed)
    stdout.write("--- ")
    resetAttributes()
    echo oldv.label & ": " & $oldv.value
  if newv.value != newJNull():
    stdout.setForegroundColor(fgGreen)
    stdout.write("+++ ")
    resetAttributes()
    echo newv.label & ": " & $newv.value 
  return confirm("Confirm change?")

let usage* = """  $1 v$2 - $3
  (c) 2017-2018 Fabio Cevasco

  Usage:
    nifty <command> [<package>]           Executes <command> (on <package>).

    For more information on available commands, run: nifty help

  Options:
    --log, -l               Specifies the log level (debug|info|notice|warn|error|fatal).
                            Default: info
    --help, -h              Displays this message.
    --version, -h           Displays the version of the application.
""" % [appname, version, appdesc]

var args = newSeq[string](0)
var opts = newSeq[NiftyOption](0)

proc `%`(opts: seq[NiftyOption]): JsonNode =
  result = newJObject()
  for o in opts:
    result[o.key] = o.val

proc confirmAndRemoveDir(dir: string) =
  warn "Delete directory '$1' and all its contents? [y/n]" % dir
  let answer = stdin.readLine.toLowerAscii[0]
  if answer == 'y':
    dir.removeDir()

proc confirmAndRemoveFile(file: string) =
  warn "Delete file '$1'? [y/n]" % file 
  let answer = stdin.readLine.toLowerAscii[0]
  if answer == 'y':
    file.removeFile()

proc confirmAndRemovePackage(pkg: string) =
  if pkg.fileExists():
    pkg.confirmAndRemoveFile()
  elif pkg.dirExists():
    pkg.confirmAndRemoveDir()
  else:
    warn "Package '$1' not found." % pkg

for kind, key, val in getopt():
  case kind:
    of cmdArgument:
      args.add key 
    of cmdLongOption, cmdShortOption:
      case key:
        of "log", "l":
          var val = val
          setLogLevel(val)
        of "help", "h":
          echo usage
          quit(0)
        of "version", "v":
          echo version
          quit(0)
        else:
          var v: JsonNode
          if val == "true" or val == "":
            v = %true
          else:
            v = %val
          opts.add NiftyOption(key: key, val: v)
    else:
      discard

proc walkPkgs(prj: NiftyProject, dir: string, level = 1) =
  for k, v in prj.packages.pairs:
    echo " ".repeat(level*2) &  "-" & " " & k
    var d = dir / prj.storage / k
    var p = newNiftyProject(d)
    if p.configured:
      p.load
      walkPkgs(p, d, level+1)

proc updateDefinitions(prj: var NiftyProject): bool =
  result = false
  let sysCommands = niftyTpl.parseJson["commands"]
  for k, v in sysCommands.pairs:
    if prj.commands.hasKey(k):
      let sysCommand = sysCommands[k]
      var prjCommand = prj.commands[k]
      for prop, val in sysCommand.pairs:
        let sysProp = sysCommand[prop]
        var prjProp = newJNull()
        if prjCommand.hasKey(prop):
          prjProp = prjCommand[prop]
        if prjProp != newJNull():
          if prjProp != sysProp:
            let sysVal = (label: k & "." & prop, value: sysProp)
            let prjVal = (label: k & "." & prop, value: prjProp)
            if changeValue(prjVal, sysVal):
              prjCommand[prop] = sysProp
              result = true
        else:
          result = true
          # Adding new property
          stdout.setForegroundColor(fgGreen)
          stdout.write("+++ ")
          resetAttributes()
          echo "$1.$2: $3" % [k, prop, $sysProp] 
          prjCommand[prop] = sysProp
    else:
      result = true
      # Adding new command
      stdout.setForegroundColor(fgGreen)
      stdout.write("+++ ")
      resetAttributes()
      echo "$1: $2" % [k, $sysCommands[k]] 
      prj.commands[k] = sysCommands[k]

var prj = newNiftyProject(getCurrentDir())

if args.len == 0:
  echo usage
  quit(0)
case args[0]:
  of "init":
    if prj.configured:
      fatal "Project already configured."
      quit(2)
    var storage = "packages"
    if args.len > 2:
      storage = args[1]
    prj.init(storage)
    notice "Project initialized using '$1' as storage directory." % storage
  of "map":
    if args.len < 2:
      fatal "No package alias specified."
      quit(3)
    prj.map(args[1], %opts) 
  of "unmap":
    if args.len < 2:
      fatal "No package alias specified."
      quit(3)
    prj.unmap(args[1]) 
  of "remove":
    prj.load
    if args.len < 2:
      var packages = toSeq(prj.packages.pairs)
      if packages.len == 0:
        warn "No packages defined - nothing to do."
      else:
        for key, val in prj.packages.pairs:
          confirmAndRemovePackage(prj.storage/key)
    else:
      confirmAndRemovePackage(prj.storage/args[1])
  of "list":
    prj.load
    let pwd = getCurrentDir()
    let parts = pwd.split(DirSep)
    echo parts[parts.len-1]
    walkPkgs(prj, pwd)
  of "info":
    if args.len < 2:
      fatal "No package alias specified."
      quit(3)
    prj.load
    let alias = args[1]
    if not prj.packages.hasKey(alias):
      fatal "Package alias '$1' not defined." % [alias]
      quit(4)
    let data = prj.packages[alias]
    for k, v in data.pairs:
      echo "$1:\t$2" % [k, $v]
  of "help":
    prj.load
    if args.len < 2:
      for k, v in prj.help.pairs:
        echo "nifty $1\n    $2" % [v["_syntax"].getStr, v["_description"].getStr]
    else:
      let cmd = args[1]
      if not prj.help.hasKey(cmd):
        fatal "Command '$1' is not defined." % cmd
        quit(5)
      echo "nifty $1\n    $2" % [prj.help[cmd]["_syntax"].getStr, prj.help[cmd]["_description"].getStr]
  of "update-definitions":
    prj.load
    if updateDefinitions(prj):
      prj.save
  else:
    if args.len < 1:
      echo usage
      quit(1)
    if args.len < 2:
      prj.load
      var packages = toSeq(prj.packages.pairs)
      if packages.len == 0:
        warn "No packages defined - nothing to do."
      else:
        for key, val in prj.packages.pairs:
          prj.executeRec(args[0], key) 
    else:
      prj.executeRec(args[0], args[1]) 
