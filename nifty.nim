import 
  json,
  os,
  parseopt2,
  logging,
  strutils

import
  lib/config,
  lib/logger

when isMainModule:
  let usage* = """  $1 v$2 - $3
  """ % [appname, version, appdesc]

  var file, s: string = ""
  setLogFilter(lvlNotice)
  
  for kind, key, val in getopt():
    case kind:
      of cmdArgument:
        file = key
      of cmdLongOption, cmdShortOption:
        case key:
          of "log", "l":
            var val = val
            setLogLevel(val)
          #of "evaluate", "e":
          #  s = val
          of "help", "h":
            echo usage
            quit(0)
          of "version", "v":
            echo version
            quit(0)
          else:
            discard
      else:
        discard