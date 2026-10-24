## Mod class used for G.T. Greg Modloader
##
## Folder format:
## [codeblock lang=text]
## user://
## └─mods
##   ├─YourMod
##   │ ├─asset1.tscn
##   │ ├─asset1.gd
##   │ ├─asset2.png
##   │ ├─manifest.json
##   │ └─main.gd
##   └─AnotherMod
##     ├─assets.pck
##     ├─manifest.json
##     ├─icon.png
##     └─main.gd
## [/codeblock]
## Clarification: [code]icon.png[/code] and [code]assetX.YZW[/code] are optional (handled by the game and by the mod, respectively), [code]main.gd[/code] and [code]manifest.json[/code] are required (both handled by the modloader)
extends Node
class_name Mod

## The manifest of your mod; [b]please[/b] only read it to not cause unexpected behaviour
var Manifest: Dictionary = {
  "name": "Mod Name Here",
  "author": "Author Name(s) Here",
  "codename": "ModNameHere-AuthorNamesHere",
  "semver": [0,0,0],
  "description": "Mod Description Here. List what you can do with it"
}
## Same as [code]get_tree().root[/code]
@onready var Root := get_tree().root
## The folder where your mod lives[br]
## Example: [code]user://mods/YourMod[/code]
var MyFolder: String

## Prints info to the console
func InfoPrint(what: String):
  print_rich("[b]INFO[/b] | %s (%s) :: %s" % [Manifest.name, Manifest.codename, what])
  
## Prints an error to the console
func ErrorPrint(what: String):
  push_error("[color=red][b]ERROR[/b] | %s (%s) :: %s[/color]" % [Manifest.name, Manifest.codename, what])

## Prints warnings to the console
func WarnPrint(what: String):
  print_rich("[color=yellow][b]WARNING[/b] | %s (%s) :: %s[/color]" % [Manifest.name, Manifest.codename, what])

## Print function used for debugging (nothing restricts you from using it)
func DebugPrint(what: String):
  print_rich("[color=yellow][b]DEBUG[/b] | %s (%s) :: %s[/color]" % [Manifest.name, Manifest.codename, what])
