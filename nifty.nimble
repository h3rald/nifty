import
  ospaths

template thisModuleFile: string = instantiationInfo(fullPaths = true).filename

when fileExists(thisModuleFile.parentDir / "src/niftypkg/config.nim"):
  # In the git repository the Nimble sources are in a ``src`` directory.
  import src/niftypkg/config
else:
  # When the package is installed, the ``src`` directory disappears.
  import niftypkg/config

# Package

version       = pkgVersion
author        = pkgAuthor
description   = pkgDescription
license       = "MIT"
bin           = @["nifty"]
srcDir        = "src"
installExt    = @["nim"]

# Dependencies

requires "nim >= 0.19.0"

const compile = "nim c -d:release"
const linux_x86 = "--cpu:i386 --os:linux -o:nifty"
const linux_x64 = "--cpu:amd64 --os:linux -o:nifty"
const linux_arm = "--cpu:arm --os:linux -o:nifty"
const windows_x64 = "--cpu:amd64 --os:windows -o:nifty.exe"
const macosx_x64 = "-o:nifty"
const program = "nifty"
const program_file = "src/nifty.nim"
const zip = "zip -X"

proc shell(command, args: string, dest = "") =
  exec command & " " & args & " " & dest

proc filename_for(os: string, arch: string): string =
  return "nifty" & "_v" & version & "_" & os & "_" & arch & ".zip"

task windows_x64_build, "Build nifty for Windows (x64)":
  shell compile, windows_x64, program_file

task linux_x86_build, "Build nifty for Linux (x86)":
  shell compile, linux_x86,  program_file
  
task linux_x64_build, "Build nifty for Linux (x64)":
  shell compile, linux_x64,  program_file
  
task linux_arm_build, "Build nifty for Linux (ARM)":
  shell compile, linux_arm,  program_file
  
task macosx_x64_build, "Build nifty for Mac OS X (x64)":
  shell compile, macosx_x64, program_file

task release, "Release nifty":
  echo "\n\n\n WINDOWS - x64:\n\n"
  windows_x64_buildTask()
  shell zip, filename_for("windows", "x64"), program & ".exe"
  shell "rm", program & ".exe"
  echo "\n\n\n LINUX - x64:\n\n"
  linux_x64_buildTask()
  shell zip, filename_for("linux", "x64"), program 
  shell "rm", program 
  echo "\n\n\n LINUX - x86:\n\n"
  linux_x86_buildTask()
  shell zip, filename_for("linux", "x86"), program 
  shell "rm", program 
  echo "\n\n\n LINUX - ARM:\n\n"
  linux_arm_buildTask()
  shell zip, filename_for("linux", "arm"), program 
  shell "rm", program 
  echo "\n\n\n MAC OS X - x64:\n\n"
  macosx_x64_buildTask()
  shell zip, filename_for("macosx", "x64"), program 
  shell "rm", program 
  echo "\n\n\n ALL DONE!"
