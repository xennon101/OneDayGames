extends Node

## Provides ID-based scene path resolution across shared systems and games.
var DEFAULT_PATHS: Dictionary = {}
var _paths: Dictionary = {}


func _init() -> void:
	_rebuild_defaults(false)


func _ready() -> void:
	_rebuild_defaults(true)


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


func _rebuild_defaults(log: bool) -> void:
	var base_path := "res://defaultTemplate/"
	var project_root := ProjectSettings.globalize_path("res://").replace("\\", "/")
	if project_root.ends_with("/"):
		project_root = project_root.substr(0, project_root.length() - 1)
	var local_boot_exists := FileAccess.file_exists("res://boot.tscn")
	var template_boot_exists := FileAccess.file_exists("res://defaultTemplate/boot.tscn")
	if local_boot_exists:
		base_path = "res://"
	elif template_boot_exists:
		base_path = "res://defaultTemplate/"
	if log:
		print("[SceneConfig] autoload setting: %s" % str(ProjectSettings.get_setting("autoload", {})))
		print("[SceneConfig] project root: %s" % project_root)
		print("[SceneConfig] base path: %s (local_boot: %s, template_boot: %s)" % [base_path, local_boot_exists, template_boot_exists])
	DEFAULT_PATHS = {
		"boot": "%sboot.tscn" % base_path,
		"main_menu": "%smain_menu.tscn" % base_path,
		"loading": "%sloading_screen.tscn" % base_path,
		"settings": "%ssettings_menu.tscn" % base_path,
		"credits": "%scredits.tscn" % base_path,
		"gameplay": "%splaceholder_game.tscn" % base_path
	}
	_paths = DEFAULT_PATHS.duplicate(true)
	if log:
		print("[SceneConfig] registered ids: %s" % str(_paths.keys()))
