import
  os,
  json,
  logging,
  strutils

type
  NiftyProject* = object
    dir: string
    storage: string
    commands: JsonNode
    packages: JsonNode


proc newNiftyProject*(dir: string): NiftyProject =
  result.dir = dir

proc configFile*(prj: NiftyProject): string = 
  return prj.dir/"nifty.json"

proc configured*(prj: NiftyProject): bool =
  return fileExists(prj.configFile)

proc init*(prj: var NiftyProject, storage: string) =
  prj.storage = storage
  createDir(prj.dir/prj.storage)
  var o = newJObject()
  o["storage"] = %prj.storage
  o["commands"] = newJObject()
  o["commands"]["install"] = newJObject()
  o["commands"]["install"]["git+src"] = %"git clone {{src}} --depth 1"
  o["commands"]["install"]["git+src+tag"] = %"git clone --branch {{tag}} {{src}} --depth 1"
  o["commands"]["update"] = newJObject()
  o["commands"]["update"]["git+name"] = %"cd {{name}} && git pull; cd .."
  o["packages"] = newJObject()
  prj.configFile.writeFile(o.pretty)

proc load*(prj: var NiftyProject) =
  let cfg = prj.configFile.parseFile
  prj.commands = cfg["commands"]
  prj.packages = cfg["packages"]

proc save*(prj: NiftyProject) = 
  var o = newJObject()
  o["storage"] = %prj.storage
  o["commands"] = %prj.commands
  o["packages"] = %prj.packages
  prj.configFile.writeFile(o.pretty)

proc map*(prj: var NiftyProject, alias: string, props: JsonNode) =
  prj.load
  if not prj.packages.hasKey alias:
    notice "Adding package definition '$1'..." % alias
    prj.packages[alias] = newJObject()
    prj.packages[alias]["name"] = %alias
  else:
    notice "Updating package definition '$1'..." % alias
  for key, val in props.pairs:
    prj.packages[alias][key] = val
    notice "  $1 = $2" % [key, $val]
  prj.save
  notice "Package definition '$1' saved." % alias
