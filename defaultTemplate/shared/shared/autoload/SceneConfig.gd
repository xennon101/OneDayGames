extends Node

## Provides ID-based scene path resolution across shared systems and games.
var DEFAULT_PATHS := {
	"boot": "res://defaultTemplate/boot.tscn",
	"main_menu": "res://defaultTemplate/main_menu.tscn",
	"loading": "res://defaultTemplate/loading_screen.tscn",
	"settings": "res://defaultTemplate/settings_menu.tscn",
	"credits": "res://defaultTemplate/credits.tscn",
	"gameplay": "res://defaultTemplate/placeholder_game.tscn"
}
var _paths: Dictionary = DEFAULT_PATHS.duplicate(true)


func _ready() -> void:
	print("[SceneConfig] autoload setting: %s" % str(ProjectSettings.get_setting("autoload", {})))
	var base_path := "res://defaultTemplate/"
	var project_root := ProjectSettings.globalize_path("res://")
	if project_root.ends_with("/defaultTemplate") or project_root.ends_with("\\defaultTemplate"):
		base_path = "res://"
	print("[SceneConfig] base path: %s" % base_path)
	DEFAULT_PATHS = {
		"boot": "%sboot.tscn" % base_path,
		"main_menu": "%smain_menu.tscn" % base_path,
		"loading": "%sloading_screen.tscn" % base_path,
		"settings": "%ssettings_menu.tscn" % base_path,
		"credits": "%scredits.tscn" % base_path,
		"gameplay": "%splaceholder_game.tscn" % base_path
	}
	_paths = DEFAULT_PATHS.duplicate(true)
	print("[SceneConfig] registered ids: %s" % str(_paths.keys()))


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
