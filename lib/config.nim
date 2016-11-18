import
  os,
  parsecfg,
  streams,
  strutils,
  logging

import
  logger

const
  cfgfile   = "../nifty.nimble".slurp

var
  appname*: string
  version*: string
  appdesc*: string
  f = newStringStream(cfgfile)

if f != nil:
  var p: CfgParser
  open(p, f, "../minim.nimble")
  while true:
    var e = next(p)
    case e.kind
    of cfgEof:
      break
    of cfgKeyValuePair:
      case e.key:
        of "version":
          version = e.value
        of "name":
          appname = e.value
        of "description":
          appdesc = e.value
        else:
          discard
    of cfgError:
      fatal("Configuration error.")
      quit(1)
    else: 
      discard
  close(p)
else:
  fatal("Cannot process configuration file.")
  quit(2)