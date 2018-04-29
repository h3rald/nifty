% Nifty User Guide
% Fabio Cevasco
% -

## Overview

{{n -> **`nifty`**}} is a simple, self-contained program that can be used as a bare-bones package manager and script runner. 

It was born out of the necessity of building {{nim -> [Nim](https://nim-lang.org)}} programs with several dependencies like [min](https://h3rald.com/min) or [hastysite](https://h3rald.com/hastysite) on machines with low memory (i.e. a VPS running x86 Linux with 500MB of RAM). The main problem was that on such low-end machine it [may not even be possible](https://github.com/nim-lang/nimble/issues/278) to compile the [Nimble](https://github.com/nim-lang/nimble) package manager, because apparently it requires more RAM to compile than Nim itself.

Nimble offers a lot of features that *proper* package managers do, like dependency management, package creation and publishing, support for semantic versioning, etc. while {{n}} does not. Hence {{n}} is only a _pseudo-_package manager and script runner, but it could be useful in certain situations nonetheless. 

### Main features

In a nutshell, {{n}} is a program that executes user-defined scripts on a set of folders or files within a user-define package folder. It doesn't do (almost) anything by itself, it just relies on other programs and utilities that are typically already available on your system like [git](https://git-scm.com) and [curl](https://curl.haxx.se) to do all the heavy-lifting.

#### Run side-by-side your existing package manager

{{n}} doesn't claim to replace your existing package manager, therefore it tries not to get too much in the way of your existing project structure. All it needs to work resides in a humble {{nj -> `nifty.json`}} file that is used to:

* keep track of what packages are part of the current project
* provide the full definition of all the available commands and how to execute them on specific packages

The folder where packages will be stored is by default set to a [packages](class:kwd) subfolder within the current project directory, but even this can be configured in the {{nj}} file. 

#### Define your own packages

For {{n}}, a package can be a folder containing files, or even a single files. Through the {{nj}} file, you can define:

* The *source* of a package (typically a git repository or event just a URL).
* Whether the package supports *git*, *curl* or any other command that will be used to retrieve its contents.


{{example-package ->
> %sidebar%
> Example package
> 
> ```
> "niftylogger.nim": {
>   "name": "niftylogger.nim",
>   "src": "https://github.com/h3rald/nifty/blob/master/lib/niftylogger.nim",
>   "curl": true
> }
> ```
}}

> %warning%
> Important
> 
> {{n}} does not support nor understand versioning of any kind. It will not attempt to figure out what version of software you need unless you tell it. This is by design, to keep things simple. 


#### Define your own commands 

You can use your {{nj}} to teach {{n}} new tricks, i.e. how to execute new commands on packages. Your commands look like... well, CLI commands, except that you can use placeholders like `{\{name}\}` and `{\{src}\}` in them for your package name, source, etc.

{{example-command ->
> %sidebar%
> Example command
> 
> ```
> "install": {
>   "_syntax": "install [<package>]",
>   "_description": "Installs the specified package (or all mapped packages) to the storage directory.",
>   "git+src": {
>     "cmd": "git clone {\{src}\} --depth 1"
>   },
>   "git+src+tag": {
>     "cmd": "git clone --branch \{\{tag\}\} \{\{src\}\} --depth 1"
>   },
>   "curl+src+name": {
>     "cmd": "curl \{\{src\}\} -o \{\{name\}\}"
>   }
> }
> ```
}}

#### Run on many different platforms and regardless of the type of project

{{n}} is a self-contained executable program written in {{nim -> [Nim](https://nim-lang.org)}} and runs on all platforms where Nim compiles. Also, unlike other package managers that are typically used within the context of one specific programming language (like [NPM](https://www.npmjs.com) for Javascript or [RubyGems](https://rubygems.org) for Ruby), {{n}} can be used in virtually any project, regardless of the programming language used.

## Getting started

### Downloading Pre-built Binaries

{# release -> [nifty for $1]({{release}}/dowload/{{$version}}/nifty_v{{$version}}_$2.zip)#}

The easiest way to get {{n}} is by downloading one of the prebuilt binaries from the [Github Releases Page]({{release -> https://github.com/h3rald/nifty/releases}}):

  * {#release||Mac OS X (x64)||macosx_x64#}
  * {#release||Windows (x64)||windows_x64#}
  * {#release||Linux (x64)||linux_x64#}
  * {#release||Linux (x86)||linux_x86#}
  * {#release||Linux (ARM)||linux_arm#}

### Building from Source

You can also build {{n}} from source, if there is no pre-built binary for your platform.

To do so, after installing the {{nim}} programming language, you can:

3. Clone the nifty [repository](https://github.com/h3rald/nifty).
4. Navigate to the [nifty](class:dir) repository local folder.
7. Run **nim c -d:release nifty.nim**

## Using nifty

To initialize a new project, run the following command within a folder (it doesn't have to be empty):

> %terminal%
> 
> nifty init
> &nbsp;&nbsp;&nbsp;&nbsp;Project initialized using 'packages' as storage directory.

{{n}} will create a file like the following:

```
{
  "storage": "packages",
  "commands": {
    "install": {
      "_syntax": "install [<package>]",
      "_description": "Installs the specified package (or all mapped packages) to the storage directory.",
      "git+src": {
        "cmd": "git clone {\{src}\} --depth 1"
      },
      "git+src+tag": {
        "cmd": "git clone --branch \{\{tag\}\} \{\{src\}\} --depth 1"
      },
      "curl+src+name": {
        "cmd": "curl \{\{src\}\} -o \{\{name\}\}"
      }
    },
    "upgrade": {
      "_syntax": "upgrade [<package>]",
      "_description": "Upgrades the specified previously-installed package (or all packages).",
      "git+name": {
        "cmd": "git pull",
        "pwd": "\{\{name\}\}"
      },
      "curl+src+name": {
        "cmd": "curl \{\{src\}\} -o \{\{name\}\}"
      }
    }
  },
  "packages": {}
}
```

### Managing packages

After initializing a project, you'd probably want to add some packages your project depends on. First, you must teach {{n}} where and how to retrieve your packages; this is done by executing the [map](#map) command, which is used essentially to add or modify a package to the {{nj}} file.

Suppose you want to include "NiftyLogger" in your project. NiftyLogger is a simple logger module written in Nim, and it is constituted by a single file, available within the nifty repository itself:

<https://github.com/h3rald/nifty/blob/master/lib/niftylogger.nim>

You can create a **niftylogger.nim** package by running `nifty map niftylogger.nim` and specifying some properties that will help {{n}} manage your package:

> %terminal%
> nifty map niftylogger
>     Mapping new package: niftylogger
> (!) Specify properties for package &apos;niftylogger&apos;:
>    -> Name: src
>    -> Value: &quot;https://github.com/h3rald/nifty/blob/master/lib/niftylogger.nim&quot;
> (!) OK? [y/n]: y
> (!) Do you want to add/remove more properties? [y/n]: y
>    -> Name: curl
>    -> Value: true
> (!) OK? [y/n]: y
> (!) Do you want to add/remove more properties? [y/n]: n
>     Adding package mapping &apos;niftylogger&apos;&period;&period;&period;
>       src: &quot;https://github.com/h3rald/nifty/blob/master/lib/niftylogger.nim&quot;
>       curl: true
>     Package mapping &apos;niftylogger&apos; saved.

The resulting package definition within the {{nj}} file is the following:


 #example_package#

{{example-package}}

You can now:

* Install the package using the [install](#install) command.
* Remove the package mapping using the [unmap](#unmap)

### Managing commands

By default, when you [initialize a project](#Using-nifty) the generated {{nj}} file contains two default custom command configurations:

* [install](#install)
* [upgrade](#upgrade)

These commands can be used to respectively install and upgrade packages using git or curl. Consider for example the definition of the **install** command:


 #example_command#

{{example-command}}

Apart for the **_syntax** and the **_description** properties that are used internally by the [help](#help) command, the other properties specify different command-line commands to execute on projects, depending on the properties that have been defined for them.

### Executing commands

Considering for example the [example of package definition](#example_package) for niftylogger, executing `nifty install niftylogger` will effectively execute the following command:

`curl https://github.com/h3rald/nifty/blob/master/lib/niftylogger.nim -o niftylogger.nim`

Essentially, when a command is executed, {{n}} will:

1. Retrieve the specified package definition within the {{nj}} file.
2. Retrieve the specified command within the {{nj}} file.
3. find a suitable definition for the specified package. Essentially, {{n}} will try to look for the command definition related to the specified command that most closely matches the properties defined for the specified package.

In this case, given the [example install command](#example_command) and the [example niftylogger package](#example_package):

1. The package definition for **niftylogger** is retrieved.
2. The command configuration for **install** is retrieved.
3. The **git+src** command definition is retrieved, because:
    > %unstyled%
    > * [](class:square) The definition **git+src+tag** cannot be used, because niftylogger does not contain a **git** or a **tag** property. 
    > * [](class:square) The definition **git+src** cannot be used, because niftylogger does not contain a **git** property. 
    > * [](class:check) The definition **curl+src+name** is used, because niftylogger has a **name**, a **src**, and a **curl** property.

> %sidebar%
> Command execution rules
> 
> * If a package is specified when executing a command, the command will be executed only on the specified package.
> * If the specified package is also a valid {{n}} project (i.e. it contains a valid {{nj}} file), the same command will be executed on all the packages specified in the {{nj}} file, and so on, recursively.
> * If no packages are specified when executing a command, that command will be executed on *all packages* specified in the {{nj}} file, recursively.

In a similar way, you can modify the [commands](#commands) section of the {{nj}} file and create your own command configurations. Each command configuration can have one or more command definitions identified by the property placeholders used.

> %tip%
> Tip
> 
> {{n}} will always try to match the most specific command definition within any given configuration, i.e. the one with the most matching placeholders.


## The {{nj}} file format


The {{nj}} file contains information on the current _project_ (for {{n}}, a project is simply a folder with a {{nj}} in it), organized into three main sections:

* storage
* commands
* packages

The following is an example of {{nj}} file taken from the [min](https://github.com/h3rald/min) repository:


```
{
  "storage": "packages",
  "commands": {
    "install": {
      "git+src": {
        "cmd": "git clone {\{src}\} --depth 1"
      },
      "git+src+tag": {
        "cmd": "git clone --branch {\{tag}\} {\{src}\} --depth 1"
      },
      "curl+src+name": {
        "cmd": "curl {\{src}\} -o {\{name}\}"
      },
      "_syntax": "install [<package>]",
      "_description": "Installs the specified package (or all mapped packages) to the storage directory."
    },
    "upgrade": {
      "_syntax": "upgrade [<package>]",
      "_description": "Upgrades the specified previously-installed package (or all packages).",
      "git+name": {
        "cmd": "git pull",
        "pwd": "{\{name}\}"
      },
      "curl+src+name": {
        "cmd": "curl {\{src}\} -o {\{name}\}"
      }
    }
  },
  "packages": {
    "nim-sgregex": {
      "name": "nim-sgregex",
      "src": "https://github.com/h3rald/nim-sgregex.git",
      "git": true
    },
    "nim-miniz": {
      "name": "nim-miniz",
      "src": "https://github.com/h3rald/nim-miniz.git",
      "git": true
    },
    "nimSHA2": {
      "name": "nimSHA2",
      "src": "https://github.com/jangko/nimSHA2.git",
      "git": true
    },
    "sha1": {
      "name": "sha1",
      "src": "https://github.com/onionhammer/sha1.git",
      "git": true
    },
    "nimline": {
      "name": "nimline",
      "src": "https://github.com/h3rald/nimline.git",
      "git": true
    },
    "niftylogger.nim": {
      "name": "niftylogger.nim",
      "src": "https://raw.githubusercontent.com/h3rald/nifty/master/lib/niftylogger.nim",
      "curl": true
    }
  }
}
```

### storage

This property is used to specify which directory within the current directory contains (or will contain) packages. By default, it is set to **packages**.

### commands

Custom command configurations are placed within the `commands` object. Each command typically contains the following system properties:

\_syntax
: The syntax of the command, displayed when the [help](#help) command is executed.
\_description
: A brief description of the command, displayed when the [help](#help) command is executed.

And one or more command definitions, each identified by the placeholders used in it. Command definition contain the following properties:

cmd
: A command to execute on a specified, containing placeholders for package properties. By default, the **name** property is always available for all packages, and corresponds to the package identifier. 
pwd _(optional)_
: The directory where the command will be executed (relative to the [storage](#storage) directory specified in the {{nj}} file).


> %note%
> Notes
> 
> * Command definition identifiers must be composed by plus-separated property names, e.g. **git+src**, or **wget+src+name**. 
> * You can use any of the property names specified in the command definition identifier as placeholders within its definition.

#### Command configuration example

Consider the following command configuration for the default [upgrade](#upgrade) custom command:

```
"upgrade": {
  "_syntax": "upgrade [<package>]",
  "_description": "Upgrades the specified previously-installed package (or all packages).",
  "git+name": {
    "cmd": "git pull",
    "pwd": "\{\{name\}\}"
  },
  "curl+src+name": {
    "cmd": "curl \{\{src\}\} -o \{\{name\}\}"
  }
}
```

In this case, there are two command definitions:

* git+name
* curl+src+name

### packages

Packages definitions are placed in a `packages` object. Each package must be identified uniquely by a name, and can contain arbitrary properties that will be used when [executing commands](Executing-commands).

Typically, you should create properties identifying:

* Where to get the package from, i.e. an URL to a file to download, a git repository, or whatever can be fetched. Typically a property called **src** is used for this purpose.
* How to get the package, i.e. the name of the actual command to run. Typically, you can just define boolean properties named **git**, **curl**, **fossil**, etc.

#### Package definition example

Consider the following definition for a package called **nimSHA2**:

```
"nimSHA2": {
  "name": "nimSHA2",
  "src": "https://github.com/jangko/nimSHA2.git",
  "git": true
}
```

In this case, the package can be fetchet from a git repository.

{#command -> 
### $1

#### Syntax

```
nifty $2
```

#### Description

$3 #}

## Default system commands

The following sections describe the default system commands. Unlike [custom commands](#Default-custom-commands), system commands *cannot* be customized and do not require external programs to run.

{#command||help||help [<command>]||
Display help on the specified command (or all commands).
 #}

{#command||info||info <package>|| 
Displays information on &lt;package&gt; (essentially all its properties).#}

{#command||init||init [<storage-dir>]||
Initializes a project in the current directory (using &lt;storage-dir&gt; as storage directory).#}

{#command||list||list||
Lists all dependencies (recursively) of the current project.#}

{#command||map||map <package>||
Configures a new or existing package &lt;package&gt;. 

The configuration of the package properly is interactive: {{n}} will prompt whether you want to add or modify properties.#}

{#command||remove||remove [<package>]||
Physically deletes the specified package (or all packages) from the storage directory.

This command asks for confirmation before deleting each package.#}

{#command||unmap||unmap <package>||
Unmaps the previously-mapped package &lt;package&gt;, removing all its properties from the {{nj}} file.#}

{#command||update||update||
Updates the command definitions for the current project and migrate nifty.json file (if necessary).

This program effectively updates your {{nj}} file adding/updating commands and settings, but it does not attempt to remove any custom command configurations or definitions that you may have added.#}

## Default custom commands

{#command||install||install [<package>]||
Installs the specified package (or all mapped packages) to the storage directory, using the matching command definition.

By default, the following definitions are available for this command:

```
"git+src": 
{
  "cmd": "git clone {\{src}\} --depth 1"
}, 
"git+src+tag": 
{
  "cmd": "git clone --branch {\{tag}\} {\{src}\} --depth 1"
}, 
"curl+src+name": 
{
  "cmd": "curl {\{src}\} -o {\{name}\}"
}
```#}

{#command||upgrade||upgrade [<package>]||
Upgrades the specified previously-installed package (or all packages).

By default, the following definitions are available for this command:

```
"git+name": 
{
  "cmd": "git pull", 
  "pwd": "{\{name}\}"
}, 
"curl+src+name": 
{
  "cmd": "curl {\{src}\} -o {\{name}\}"
}
```#}
