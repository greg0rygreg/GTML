extends Node

# configurables
## Mods folder location[br]
## Default: [code]user://mods[/code]
const MODS_DIR: String = "user://mods"

# code
## Format: [code][major, minor, patch][/code][br]
## Same applies to [code]Mod[/code]s
##
## Compare using comparison operators
const VERSION: Array[int] = [0,3,1]
var loadedmods: Array[Mod]
var _modsfolder := DirAccess.open(MODS_DIR)

signal all_done
signal mod_loaded(mod: Mod)

func _ready() -> void:
  # wait for every node in root to get ready
  await get_parent().ready
  
  # check for no mods mode
  if "--no-mods" in OS.get_cmdline_user_args():
    print_rich("[color=yellow][b]GTML WARNING[/b] :: No Mods mode has been enabled; GTML init skipped[/color]")
    return
  
  # append every loaded mod to loadedmods array
  mod_loaded.connect(loadedmods.append)
  
  # check for null mods folder
  if _modsfolder == null:
    DirAccess.make_dir_absolute(MODS_DIR)
    _modsfolder = DirAccess.open(MODS_DIR)

  # get every mod in modsloc
  var mods := _modsfolder.get_directories()
  for modfolder: String in mods:
    # check for disabled mods
    if modfolder.begins_with("_"):
      print_rich("[color=yellow][b]GTML WARNING[/b] :: %s is disabled; skipped[/color]" % MODS_DIR.path_join(modfolder))
      continue
    
    var mod := DirAccess.open(MODS_DIR.path_join(modfolder))
    
    # check for manifest.json
    if !mod.file_exists("manifest.json"):
      print_rich("[color=yellow][b]GTML WARNING[/b] :: %s doesn't have a manifestation; skipped[/color]" % MODS_DIR.path_join(modfolder))
      continue
    
    # check for mods with no mods
    if !mod.file_exists("main.gd"):
      print_rich("[color=yellow][b]GTML WARNING[/b] :: %s doesn't have a main.gd; skipped[/color]" % MODS_DIR.path_join(modfolder))
      continue
    
    # load mods
    var loadthisone: Node = load(MODS_DIR.path_join(modfolder).path_join("main.gd")).new()
    if loadthisone is not Mod:
      print_rich("[color=yellow][b]GTML WARNING[/b] :: %s is not a Mod; queued for deletion[/color]" % MODS_DIR.path_join(modfolder))
      loadthisone.queue_free()
      continue
    
    # inject some variables into the mod's code
    var manifest := FileAccess.open(MODS_DIR.path_join(modfolder).path_join("manifest.json"), FileAccess.READ)
    loadthisone.Manifest = JSON.parse_string(manifest.get_as_text())
    # yeah....
    for i in range(len(loadthisone.Manifest.semver)):
      loadthisone.Manifest.semver[i] = int(loadthisone.Manifest.semver[i])
    manifest.close()
    loadthisone.MyFolder = MODS_DIR.path_join(modfolder)
    
    # make mods easier to manage
    get_tree().root.add_child(loadthisone)
    mod_loaded.emit(loadthisone)
    
    # tell everyone a mod has loaded
    print_rich("[b]GTML INFO[/b] :: Added %s %s by %s (%s)" % [
      loadthisone.Manifest.name,
      ".".join(loadthisone.Manifest.semver),
      loadthisone.Manifest.author,
      loadthisone.Manifest.codename
    ])
  
  all_done.emit()
