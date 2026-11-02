extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var valid: bool=true
 for path in ["res://scenes/garden/garden.tscn","res://assets/fonts/OpenSans-Regular.ttf","res://scripts/ui/static_art_cache.gd"]:
  valid=valid and ResourceLoader.exists(path)
 for code in ["en","ru","pl","es","de","fr","pt_BR"]:
  valid=valid and ResourceLoader.exists("res://localization/ui."+code+".translation")
 for path in ["res://assets/fonts/OpenSans-LICENSE.txt","res://assets/LICENSES.md"]:
  valid=valid and FileAccess.file_exists(path)
 for path in ["res://scripts/tests","res://tests","res://docs"]:
  valid=valid and (not DirAccess.dir_exists_absolute(path) or DirAccess.get_files_at(path).is_empty())
 print("PACK CONTENTS: ","PASS" if valid else "FAIL")
 quit(0 if valid else 1)
