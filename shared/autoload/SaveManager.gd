extends Node

const SAVE_PATH := "user://savegame.save"
const SAVE_PATH_FALLBACK := "res://tmp/savegame.save"

var game_supports_saves: bool = false


func has_save() -> bool:
	var primary := ProjectSettings.globalize_path(SAVE_PATH)
	var fallback := ProjectSettings.globalize_path(SAVE_PATH_FALLBACK)
	return FileAccess.file_exists(primary) or FileAccess.file_exists(fallback)


func save_game(data: Dictionary) -> void:
	if not game_supports_saves:
		return
	var dir_path := ProjectSettings.globalize_path("user://")
	DirAccess.make_dir_recursive_absolute(dir_path)
	var path := ProjectSettings.globalize_path(SAVE_PATH)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		var fallback_dir := ProjectSettings.globalize_path("res://tmp")
		DirAccess.make_dir_recursive_absolute(fallback_dir)
		path = ProjectSettings.globalize_path(SAVE_PATH_FALLBACK)
		file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("SaveManager: unable to open save file for writing.")
		return
	file.store_string(JSON.stringify(data))
	file.close()


func load_game() -> Dictionary:
	if not game_supports_saves or not has_save():
		return {}
	var path := ProjectSettings.globalize_path(SAVE_PATH)
	if not FileAccess.file_exists(path):
		path = ProjectSettings.globalize_path(SAVE_PATH_FALLBACK)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var content: String = file.get_as_text()
	file.close()
	var result: Variant = JSON.parse_string(content)
	if typeof(result) == TYPE_DICTIONARY:
		return result
	push_warning("SaveManager: corrupt save file, clearing.")
	_clear_save()
	return {}


func _clear_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
