extends Node

# Entry point that hands off to the boot scene via SceneManager.
func _ready() -> void:
	print("[Main] ready: checking SceneManager autoload")
	var singletons: Dictionary = ProjectSettings.get_setting("autoload", {})
	print("[Main] autoload settings keys: %s" % str(singletons.keys()))
	print("[Main] autoload SceneManager path: %s" % ProjectSettings.get_setting("autoload/SceneManager", ""))
	print("[Main] project root: %s" % ProjectSettings.globalize_path("res://"))
	print("[Main] Engine singletons: %s" % str(Engine.get_singleton_list()))
	print("[Main] Root children before ensure: %s" % str(_root_child_names()))
	_ensure_autoloads()
	print("[Main] Root children after ensure: %s" % str(_root_child_names()))
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


func _ensure_autoloads() -> void:
	var autoloads := {
		"SceneConfig": "res://shared/autoload/SceneConfig.gd",
		"EventBus": "res://shared/autoload/EventBus.gd",
		"ConfigManager": "res://shared/autoload/ConfigManager.gd",
		"InputManager": "res://shared/autoload/InputManager.gd",
		"AudioManager": "res://shared/autoload/AudioManager.gd",
		"SaveManager": "res://shared/autoload/SaveManager.gd",
		"LegalManager": "res://shared/autoload/LegalManager.gd",
		"SceneManager": "res://shared/autoload/SceneManager.gd"
	}
	for autoload_name in autoloads.keys():
		if get_tree().get_root().has_node(autoload_name):
			continue
		var script_path: String = autoloads[autoload_name]
		var res := ResourceLoader.load(script_path)
		if res == null:
			print("[Main] Failed to load autoload %s from %s" % [autoload_name, script_path])
			continue
		var inst = res.new()
		inst.name = autoload_name
		get_tree().get_root().add_child(inst)
		print("[Main] Injected autoload %s from %s" % [autoload_name, script_path])


func _root_child_names() -> Array:
	var names: Array = []
	for child in get_tree().get_root().get_children():
		names.append(child.name)
	return names
