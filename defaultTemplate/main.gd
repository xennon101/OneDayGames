extends Node

# Entry point that hands off to the boot scene via SceneManager.
func _ready() -> void:
	print("[Main] ready: checking SceneManager autoload")
	var singletons: Dictionary = ProjectSettings.get_setting("autoload", {})
	print("[Main] autoload settings keys: %s" % str(singletons.keys()))
	print("[Main] project root: %s" % ProjectSettings.globalize_path("res://"))
	print("[Main] Engine singletons: %s" % str(Engine.get_singleton_list()))
	if Engine.has_singleton("SceneManager"):
		var sm = Engine.get_singleton("SceneManager")
		print("[Main] SceneManager found, changing to boot")
		sm.change_scene("boot", false)
	else:
		print("[Main] SceneManager missing")
