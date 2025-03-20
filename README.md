# Fancy NuMan

This is the fancy NuShell Manager for Modules and scripts. It is a simple tool to manage your NuShell modules and scripts.

## Why NuMan?

While NuShell seems to have a native nupm package manager, it is not yet available. NuMan is a simple tool to manage your NuShell modules and scripts in the meanwhile.

## Installation

You can install NuMan using the following command: (using nushell)

```shell
git clone https://github.com/fancy-whale/fancynuman.git ($nu.default-config-dir | path join "modules/fancynuman")
echo "\nuse fancynuman *" | save --append $nu.config-path
```

## Usage

FancyNuman provides a simple interface to manage your NuShell modules and scripts. You can use the following commands to manage your modules and scripts:

```shell
numan list # lists all the installed modules and scripts
numan mod add <module-repo> # adds a module to the NuShell
numan mod remove <module-name> # removes a module from the NuShell
numan script add <script-repo> # adds a script to the NuShell
numan script remove <script-name> # removes a script from the NuShell
```

