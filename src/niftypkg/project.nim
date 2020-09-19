import
  os,
  json,
  logging,
  strutils,
  sequtils,
  pegs

type
  NiftyProject* = object
    dir*: string
    storage*: string
    commands*: JsonNode
    packages*: JsonNode
    tasklists*: JsonNode

const niftyTpl* = "nifty.json".slurp
const systemHelp = "help.json".slurp

let placeholder = peg"'{{' {[^}]+} '}}'"

proc newNiftyProject*(dir: string): NiftyProject =
  result.dir = dir

proc configFile*(prj: NiftyProject): string = 
  return prj.dir/"nifty.json"

proc configured*(prj: NiftyProject): bool =
  return fileExists(prj.configFile)

proc init*(prj: var NiftyProject, storage: string) =
  prj.storage = storage
  createDir(prj.dir/prj.storage)
  var o = parseJson(niftyTpl % [prj.storage])
  prj.configFile.writeFile(o.pretty)

proc load*(prj: var NiftyProject) =
  if not prj.configFile.fileExists:
    fatal "Project not initialized - configuration file not found."
    quit(10)
  let cfg = prj.configFile.parseFile
  prj.storage = cfg["storage"].getStr
  prj.storage.createDir()
  prj.commands = cfg["commands"]
  prj.packages = cfg["packages"]
  if cfg.hasKey("tasklists"):
    prj.tasklists = cfg["tasklists"]
  if cfg.hasKey("dir"):
    prj.dir = cfg["dir"].getStr

proc help*(prj: var NiftyProject): JsonNode =
  result = systemHelp.parseJson
  if prj.configured:
    prj.load
    for k, v in prj.tasklists.pairs:
      let syntax = "$$$1" % k
      let description = "Executes: $1" % v.elems.mapIt(it.getStr).join(", ")
      result["$"&k] = ("""
        {
          "_syntax": "$1",
          "_description": "$2"
        }
      """ % [syntax, description]).parseJson  
    for k, v in prj.commands.pairs:
      if v.hasKey("_syntax") and v.hasKey("_description"):
        result[k] = ("""
          {
            "_syntax": "$1",
            "_description": "$2"
          }
        """ % [v["_syntax"].getStr, v["_description"].getStr]).parseJson

proc save*(prj: NiftyProject) = 
  var o = newJObject()
  o["storage"] = %prj.storage
  o["commands"] = %prj.commands
  o["packages"] = %prj.packages
  prj.configFile.writeFile(o.pretty)

proc map*(prj: var NiftyProject, alias: string, props: var JsonNode) =
  for k, v in props.mpairs:
    if v == newJNull():
      props.delete(k)
  prj.load
  if not prj.packages.hasKey alias:
    notice "Adding package mapping '$1'..." % alias
    prj.packages[alias] = newJObject()
    prj.packages[alias]["name"] = %alias
  else:
    notice "Updating package mapping '$1'..." % alias
    prj.packages[alias] = newJObject()
  for key, val in props.pairs:
    prj.packages[alias][key] = val
    notice "  $1: $2" % [key, $val]
  prj.save
  notice "Package mapping '$1' saved." % alias

proc unmap*(prj: var NiftyProject, alias: string) =
  prj.load
  prj.packages.delete(alias)
  prj.save
  notice "Package mapping '$1' removed." % alias

proc lookupCommand(prj: NiftyProject, command: string, props: seq[string], cmd: var JsonNode): bool =
  if not prj.commands.hasKey command:
    warn "Command '$1' not found" % command
    return
  var cmds = prj.commands[command]
  var score = 0
  # Cycle through command definitions
  for key, val in cmds:
    if key == "_syntax" or key == "_description":
      continue
    var params = key.split("+")
    # Check if all params are available
    var match = params.all do (x: string) -> bool:
      props.contains(x)
    if match and params.len > score:
      score = params.len
      cmd = val
  return score > 0
  
proc execute*(prj: var NiftyProject, command, alias: string): int =
  prj.load
  if not prj.packages.hasKey alias:
    warn "Package definition '$1' not found within $2. Nothing to do." % [alias, prj.dir]
    return
  notice "$1: $2" % [command, alias]
  let package = prj.packages[alias]
  var keys = newSeq[string](0)
  for key, val in package.pairs:
    keys.add key
  var res: JsonNode
  var cmd: string
  var pwd = prj.storage
  if package.hasKey("dir"):
    pwd = package["dir"].getStr
  if prj.lookupCommand(command, keys, res):
    cmd = res["cmd"].getStr.replace(placeholder) do (m: int, n: int, c: openArray[string]) -> string:
      return package[c[0]].getStr
    if res.hasKey("pwd"):
      pwd = res["pwd"].getStr.replace(placeholder) do (m: int, n: int, c: openArray[string]) -> string:
        return package[c[0]].getStr
      pwd = prj.storage/pwd
    notice "Executing: $1" % cmd
    pwd.createDir()
    pwd.setCurrentDir()
    result = execShellCmd cmd
  else:
    debug "Command '$1' not available for package '$2'" % [command, alias]
  setCurrentDir(prj.dir)

proc executeRec*(prj: var NiftyProject, command, alias: string) =
  prj.load
  let pwd = getCurrentDir()
  var dir = alias
  if (execute(prj, command, alias) != 0):
    return
  if prj.packages[alias].hasKey("dir"):
    dir = prj.packages[alias]["dir"].getStr
  var childProj = newNiftyProject(pwd/prj.storage/dir)
  if childProj.configured:
    childProj.load()
    setCurrentDir(childProj.dir)
    for key, val in childProj.packages.pairs:
      childProj.executeRec(command, key)
    setCurrentDir(pwd)
