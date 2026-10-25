extends Node

# configurables
## Mods folder location[br]
## Default: [code]user://mods[/code]
const MODS_DIR: String = "user://mods"



# code
const Manifest: Dictionary = {
  "name": "G.T. Greg Modloader",
  "author": "greg0rygreg",
  "codename": "greg0rygreg-GTML",
  "semver": [0,5,1],
  "description": "Barebones-ish modloader for Godot"
}
var loadedmods: Dictionary[String, Mod]
var _modsfolder := DirAccess.open(MODS_DIR)

signal all_done
signal mod_loaded(mod: Mod)
signal mod_unloaded(mod: Mod)

## Logging class used for logging things to the console
class Logging:
  ## Logging levels: information, debug info, warnings and errors
  enum Levels {
    INFO,
    DEBUG,
    WARNING,
    ERROR
  }

  ## Logs to console
  static func write(what: String, manifest: Dictionary, level: Levels = Levels.INFO) -> void:
    print_rich("%s[b]%s[/b] | %s (%s) :: %s%s" % [
      ["", "[color=cyan]", "[color=yellow]", "[color=red]"][level as int],
      ["INFO", "DEBUG", "WARN", "ERROR"][level as int],
      manifest.name,
      manifest.codename,
      what,
      ["", "[/color]", "[/color]", "[/color]"][level as int]
    ])

func _ready() -> void:
  # wait for every node in root to get ready
  await get_parent().ready

  # check for no mods mode
  if "--no-mods" in OS.get_cmdline_user_args():
    Logging.write("No Mods is enabled; initialization skipped", Manifest, Logging.Levels.WARNING)
    return

  Logging.write("Started", Manifest, Logging.Levels.DEBUG)

  # signal shenanigans
  mod_loaded.connect(func(mod: Mod): loadedmods[mod.Manifest.codename] = mod)
  mod_unloaded.connect(func(mod: Mod): mod.queue_free())
  all_done.connect(loadedmods.make_read_only.call)

  # check for null mods folder
  if _modsfolder == null:
    DirAccess.make_dir_absolute(MODS_DIR)
    _modsfolder = DirAccess.open(MODS_DIR)

  # get every mod in modsloc
  var mods := _modsfolder.get_directories()
  for modfolder: String in mods:
    # check for disabled mods
    if modfolder.begins_with("_"):
      Logging.write("%s starts with underscore; skipped" % MODS_DIR.path_join(modfolder), Manifest, Logging.Levels.DEBUG)
      continue

    var mod := DirAccess.open(MODS_DIR.path_join(modfolder))

    # check for manifest.json
    if !mod.file_exists("manifest.json"):
      Logging.write("%s doesn't have a manifest.json; skipped" % MODS_DIR.path_join(modfolder), Manifest, Logging.Levels.DEBUG)
      continue

    # check for mods with no mods
    if !mod.file_exists("main.gd"):
      Logging.write("%s doesn't have a main.gd; skipped" % MODS_DIR.path_join(modfolder), Manifest, Logging.Levels.DEBUG)
      continue

    # check for correct classes
    var mod_script: GDScript = load(MODS_DIR.path_join(modfolder).path_join("main.gd"))
    if mod_script.get_base_script() == null:
      Logging.write("%s was about to crash GTML; skipped" % MODS_DIR.path_join(modfolder), Manifest, Logging.Levels.WARNING)
      continue
    if mod_script.get_base_script().get_global_name() != "Mod":
      Logging.write("%s is not of type Mod; skipped" % MODS_DIR.path_join(modfolder), Manifest, Logging.Levels.WARNING)
      continue

    # load mod
    var mod_instance: Node = mod_script.new()

    # inject some variables into the mod's code
    var manifest := FileAccess.open(MODS_DIR.path_join(modfolder).path_join("manifest.json"), FileAccess.READ)
    mod_instance.Manifest = JSON.parse_string(manifest.get_as_text())
    # yeah....
    for i in range(len(mod_instance.Manifest.semver)):
      mod_instance.Manifest.semver[i] = int(mod_instance.Manifest.semver[i])
    manifest.close()

    # tell everyone a mod has LOADED, not INSTANTIATED
    mod_loaded.emit(mod_instance)
    Logging.write("Loaded %s" % mod_instance.Manifest.codename, Manifest)

  # check for conflicts
  var tounload: Array[String]
  for mod: Mod in loadedmods.values():
    for conflict: String in mod.Manifest.conflict:
      if conflict in loadedmods:
        Logging.write("%s conflicts with %s; first removed" % [conflict, mod.Manifest.codename], Manifest, Logging.Levels.ERROR)
        tounload.append(conflict)
  for mod: String in tounload:
    mod_unloaded.emit(loadedmods[mod])
    loadedmods.erase(mod)

  # tell everyone a mod has instantiated
  for mod: Mod in loadedmods.values():
    Logging.write("Loaded %s" % mod.Manifest.codename, Manifest)
    get_tree().root.add_child(mod)

  all_done.emit()
