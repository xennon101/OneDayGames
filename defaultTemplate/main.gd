extends Node

# Entry point that hands off to the boot scene via SceneManager.
func _ready() -> void:
	print("[Main] ready: checking SceneManager autoload")
	var singletons: Dictionary = ProjectSettings.get_setting("autoload", {})
	print("[Main] autoload settings keys: %s" % str(singletons.keys()))
	print("[Main] autoload SceneManager path: %s" % ProjectSettings.get_setting("autoload/SceneManager", ""))
	print("[Main] project root: %s" % ProjectSettings.globalize_path("res://"))
	print("[Main] Engine singletons: %s" % str(Engine.get_singleton_list()))
	var sm = _get_scene_manager()
	if sm:
		print("[Main] SceneManager found, changing to boot")
		sm.change_scene("boot", false)
	else:
		print("[Main] SceneManager missing")


func _get_scene_manager() -> Object:
	if Engine.has_singleton("SceneManager"):
		return Engine.get_singleton("SceneManager")
	if get_tree().has_node("/root/SceneManager"):
		return get_tree().get_node("/root/SceneManager")
	return null
