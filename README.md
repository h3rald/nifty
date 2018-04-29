[![Release](https://img.shields.io/github/release/h3rald/nifty.svg)](https://github.com/h3rald/nifty)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/h3rald/nifty/master/LICENSE)

# Nifty

*nifty* is a decentralized (pseudo) package manager and script runner written in [Nim](https://nim-lang.org).

## Main features

In a nutshell, *nifty* is a program that executes user-defined scripts on a set of folders or files within a user-define package folder. It doesn't do (almost) anything by itself, it just relies on other programs and utilities that are typically already available on your system like [git](https://git-scm.com) and [curl](https://curl.haxx.se) to do all the heavy-lifting.

### Run side-by-side your existing package manager

*nifty* doesn't claim to replace your existing package manager, therefore it tries not to get too much in the way of your existing project structure. All it needs to work resides in a humble `nifty.json` file that is used to:

* keep track of what packages are part of the current project
* provide the full definition of all the available commands and how to execute them on specific packages

The folder where packages will be stored is by default set to a [packages](class:kwd) subfolder within the current project directory, but even this can be configured in the `nifty.json` file. 

&rarr; For an example of `nifty.json` file, see [the one used by HastyScribe](https://github.com/h3rald/hastyscribe/blob/master/nifty.json).

### Define your own packages

For *nifty*, a package can be a folder containing files, or even a single files. Through the `nifty.json` file, you can define:

* The *source* of a package (typically a git repository or event just a URL).
* Whether the package supports *git*, *curl* or any other command that will be used to retrieve its contents.

### Define your own commands 

You can use your `nifty.json` to teach *nifty* new tricks, i.e. how to execute new commands on packages. Your commands look like... well, CLI commands, except that you can use placeholders like `{{name}}` and `{{src}}` in them for your package name, source, etc.

### Run on many different platforms and regardless of the type of project

*nifty* is a self-contained executable program written in {{nim -> [Nim](https://nim-lang.org)}} and runs on all platforms where Nim compiles. Also, unlike other package managers that are typically used within the context of one specific programming language (like [NPM](https://www.npmjs.com) for Javascript or [RubyGems](https://rubygems.org) for Ruby), *nifty* can be used in virtually any project, regardless of the programming language used.

## Usage

nifty help [lt;commandgt;]
: Display help on the specified command (or all commands).
nifty info lt;packagegt;
: Displays information on lt;packagegt;
nifty init [lt;storage-dirgt;]
: Initializes a project in the current directory (using lt;storage-dirgt; as storage directory).
nifty list
: Lists all dependencies (recursively) of the current project.
nifty map lt;packagegt;
: Configures a new or existing package lt;packagegt;.
nifty remove [lt;packagegt;]
: Removes the specified package (or all packages) from the storage directory.
nifty unmap lt;packagegt;
: Unmaps the previously-mapped package lt;packagegt;.
nifty update
: Updates the command definitions for the current project and migrate nifty.json file (if necessary).
nifty install [lt;packagegt;]
: Installs the specified package (or all mapped packages) to the storage directory.
nifty upgrade [lt;packagegt;]
: Upgrades the specified previously-installed package (or all packages).
