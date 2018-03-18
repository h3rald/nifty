import 
  json,
  os,
  ospaths,
  parseopt,
  logging,
  strutils,
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


let usage* = """  $1 v$2 - $3
  (c) 2017-2018 Fabio Cevasco
  Commands:
    init [--storage:<dir>]                Initializes a project in the current directory.
    map <package> [--<property>:<value>]  Defines <package> with the specified properties.
    unmap <package>                       Unmaps a previously-mapped package <package>.
    remove <package>                      Removes <storage-dir>/<package> directory
                                          and all its contents.
    <command> [<package>]                 Executes <command> (on <package>).
  Options:
    --log, -l               Specifies the log level (default: info).
    --help, -h              Displays this message.
    --version, -h           Displays the version of the application.
    --storage, -s           Specifies what directory to use for storing packages.
""" % [appname, version, appdesc]

var storage = "packages"

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

proc walkPkgs(prj: NiftyProject, dir: string, level = 1) =
  for k, v in prj.packages.pairs:
    echo " ".repeat(level*2) &  "-" & " " & k
    var d = dir / prj.storage / k
    var p = newNiftyProject(d)
    if p.configured:
      p.load
      walkPkgs(p, d, level+1)


var prj = newNiftyProject(getCurrentDir())

if args.len == 0:
  echo usage
  quit(0)
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
