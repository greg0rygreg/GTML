# GTML (G.T. Greg Modloader)
Barebones-ish modloader for Godot (made by G.T. Greg of couse)

# why?
I refuse to read and know [allat](https://wiki.godotmodding.com/)

# Using GTML...
## ...as a mod user
1. Drag and drop mods to the game's mods folder (located inside the game's appdata folder by default)
2. done

## ...as a modder
1. Make a folder in the game's mods folder (located inside the game's appdata folder by default)
2. Create a `manifest.json` and a `main.gd` file
3. Inside `manifest.json`, you can use this template:
```json
{
  "name": "Mod Name Here",
  "author": "Author Name(s) Here",
  "codename": "ModNameHere-AuthorNamesHere",
  "version": "0.0.0",
  "description": "Mod Description Here. List what you can do with it"
}
```
and edit to your liking

>[!NOTE]
> It doesn't really matter what you shove in the keys as values, just go crazy all you want

4. Inside `main.gd`, you can use this template:
```gdscript
extends Mod

var asset: ImageTexture
var someoneelseslib: Mod

func _ready() -> void:
	# loading an asset from within the mod's folder
	asset = load(MyFolder.path_join("asset.png"))

	# setting something from the current scene to that asset
	Root.current_scene.get_node("Sprite2D").texture = asset

	# loading someone else's library until per-mod dependecies are added to GTML
	await Modloader.all_done
	for mod: Mod in Modloader.loadedmods:
		if mod.Manifest["codename"] == "SomeoneElse-SuperCoolLib":
			someoneelseslib = mod
			break
	# OPTIONAl: if you can't find the lib, don't load further
	if someoneelseslib == null:
		ErrorPrint("SomeoneElse-SuperCoolLib not found; queued for deletion")
		queue_free()
		return

	# using that library
	someoneelseslib.cool_function(41, 123, "abc")

	# connecting to scene changes
	get_tree().scene_changed.connect(InfoPrint.bind("Scene changed to %s" % Root.current_scene.name))

# remember, a Mod is a Node, so anything you can do with a Node, you can do with a Mod : )
```
and edit to your liking

>[!NOTE]
> It might **VERY** much matter what you shove in there, don't go too crazy

5. done

## ...as a developer
1. Drag and drop `modloader.gd` and `mod.gd` to your game's folder
2. Set `modloader.gd` as a singleton and set the name to `Modloader`
3. done


# TODO
- [ ] How-to's (**high priority**)
- [ ] Dependencies (**low priority**, you can do `await Modloader.all_done` before checking for libraries)
