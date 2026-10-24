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

## The manifest of your mod, automatically set by GTML
var Manifest: Dictionary = {
  "name": "Mod Name Here",
  "author": "Author Name(s) Here",
  "codename": "ModNameHere-AuthorNamesHere",
  "semver": [0,0,0],
  "description": "Mod Description Here. List what you can do with it"
}
## Same as [code]get_tree().root[/code]
@onready var Root := get_tree().root
## The folder where your mod lives
@onready var MyFolder: String = get_script().resource_path.get_base_dir()
## Logging class used for logging things to the console
var Logging := Modloader.Logging
