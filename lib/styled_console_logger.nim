import 
  logging,
  strutils,
  terminal

system.addQuitProc(resetAttributes)

type  
  StyledConsoleLogger* = ref object of Logger

proc logPrefix*(level: Level): tuple[msg: string, color: ForegroundColor] =
  case level:
    of lvlDebug:
      return ("---", fgMagenta)
    of lvlInfo:
      return ("(i)", fgCyan)
    of lvlNotice:
      return ("---", fgGreen)
    of lvlWarn:
      return ("(!)", fgYellow)
    of lvlError:
      return ("(!)", fgRed)
    of lvlFatal:
      return ("(x)", fgRed)
    else:
      return ("   ", fgWhite)

method log*(logger: StyledConsoleLogger; level: Level; args: varargs[string, `$`]) =
  var f = stdout
  if level >= getLogFilter() and level >= logger.levelThreshold:
    if level >= lvlWarn: 
      f = stderr
    let ln = substituteLog(logger.fmtStr, level, args)
    let prefix = level.logPrefix()
    f.setForegroundColor(prefix.color)
    f.write(prefix.msg)
    f.write(ln)
    resetAttributes()
    f.write("\n")
    if level in {lvlError, lvlFatal}: flushFile(f)

proc newStyledConsoleLogger*(levelThreshold = lvlAll; fmtStr = " "): StyledConsoleLogger =
  new result
  result.fmtStr = fmtStr
  result.levelThreshold = levelThreshold

proc getLogLevel*(): string =
  return LevelNames[getLogFilter()].toLowerAscii

proc setLogLevel*(val: var string): string {.discardable.} =
  var lvl: Level
  case val:
    of "debug":
      lvl = lvlDebug
    of "info":
      lvl = lvlInfo
    of "notice":
      lvl = lvlNotice
    of "warn":
      lvl = lvlWarn
    of "error":
      lvl = lvlError
    of "fatal":
      lvl = lvlFatal
    of "none":
      lvl = lvlNone
    else:
      val = "warn"
      lvl = lvlWarn
  setLogFilter(lvl)
  return val
