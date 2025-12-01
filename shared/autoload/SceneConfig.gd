extends Node

## Provides ID-based scene path resolution across shared systems and games.
const DEFAULT_PATHS := {
	"boot": "res://defaultTemplate/boot.tscn",
	"main_menu": "res://defaultTemplate/main_menu.tscn",
	"loading": "res://defaultTemplate/loading_screen.tscn",
	"settings": "res://defaultTemplate/settings_menu.tscn",
	"credits": "res://defaultTemplate/credits.tscn",
	"gameplay": "res://defaultTemplate/placeholder_game.tscn"
}

var _paths: Dictionary = DEFAULT_PATHS.duplicate(true)


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
