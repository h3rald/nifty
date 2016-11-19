import 
  json,
  os,
  parseopt2,
  logging,
  strutils

import
  lib/logger

newStyledConsoleLogger().addHandler()
setLogFilter(lvlInfo)

import
  lib/config,
  lib/project

type
  NiftyOption = object
    key: string
    val: JsonNode

let usage* = """  $1 v$2 - $3
""" % [appname, version, appdesc]

var command: string
var storage = "packages"

var args = newSeq[string](0)
var opts = newSeq[NiftyOption](0)

proc `%`(opts: seq[NiftyOption]): JsonNode =
  result = newJObject()
  for o in opts:
    result[o.key] = o.val

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
        of "storage", "s":
          storage = val
        else:
          var v: JsonNode
          if val == "true" or val == "":
            v = %true
          else:
            v = %val
          opts.add NiftyOption(key: key, val: v)
    else:
      discard

var prj = newNiftyProject(getCurrentDir())
case args[0]:
  of "init":
    if prj.configured:
      fatal "Project already configured."
      quit(2)
    prj.init(storage)
    notice "Project initialized using '$1' as storage directory." % storage
  of "map":
    if args.len < 2:
      fatal "No alias specified."
      quit(3)
    prj.map(args[1], %opts) 
  of "unmap":
    if args.len < 2:
      fatal "No alias specified."
      quit(3)
    prj.unmap(args[1]) 
  else:
    if args.len < 1:
      echo usage
      quit(1)
    if args.len < 2:
      prj.load
      for key, val in prj.packages.pairs:
        prj.execute(args[0], key) 
    else:
      prj.execute(args[0], args[1]) 
