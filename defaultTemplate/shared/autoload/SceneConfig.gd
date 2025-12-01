extends Node

## Provides ID-based scene path resolution across shared systems and games.
var DEFAULT_PATHS := {}
var _paths: Dictionary = {}


func _ready() -> void:
	var base_path := "res://defaultTemplate/"
	var project_root := ProjectSettings.globalize_path("res://")
	if project_root.ends_with("/defaultTemplate") or project_root.ends_with("\\defaultTemplate"):
		base_path = "res://"
	DEFAULT_PATHS = {
		"boot": "%sboot.tscn" % base_path,
		"main_menu": "%smain_menu.tscn" % base_path,
		"loading": "%sloading_screen.tscn" % base_path,
		"settings": "%ssettings_menu.tscn" % base_path,
		"credits": "%scredits.tscn" % base_path,
		"gameplay": "%splaceholder_game.tscn" % base_path
	}
	_paths = DEFAULT_PATHS.duplicate(true)


func get_scene_path(id: String) -> String:
	return _paths.get(id, "")


func has(id: String) -> bool:
	return _paths.has(id)


func all_ids() -> Array:
	return _paths.keys()


func register_scene(id: String, path: String) -> void:
	_paths[id] = path


func reset_to_defaults() -> void:
	_paths = DEFAULT_PATHS.duplicate(true)
