extends Node

const SAVE_PATH := "user://savegame.save"
const SAVE_PATH_FALLBACK := "res://tmp/savegame.save"

var game_supports_saves: bool = false
var _memory_save: Dictionary = {}


func has_save() -> bool:
	var primary := ProjectSettings.globalize_path(SAVE_PATH)
	var fallback := ProjectSettings.globalize_path(SAVE_PATH_FALLBACK)
	return not _memory_save.is_empty() or FileAccess.file_exists(primary) or FileAccess.file_exists(fallback)


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
		_memory_save = data.duplicate(true)
		return
	file.store_string(JSON.stringify(data))
	file.close()
	_memory_save.clear()


func load_game() -> Dictionary:
	if not game_supports_saves or not has_save():
		return _memory_save.duplicate(true) if not _memory_save.is_empty() else {}
	var path := ProjectSettings.globalize_path(SAVE_PATH)
	if not FileAccess.file_exists(path):
		path = ProjectSettings.globalize_path(SAVE_PATH_FALLBACK)
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _memory_save.duplicate(true)
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
