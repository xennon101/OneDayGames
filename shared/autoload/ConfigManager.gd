extends Node

const CONFIG_PATH := "user://config.cfg"
const CONFIG_PATH_FALLBACK := "res://tmp/config.cfg"

const TEMPLATE_ASSETS_CONFIG_REL := "config/template_assets.json"
const TEMPLATE_INPUT_ACTIONS_REL := "config/input_actions.json"
const TEMPLATE_AUDIO_REGISTRY_REL := "config/audio_registry.json"

const DEFAULT_CONFIG := {
	"version": 1,
	"display": {
		"fullscreen": false,
		"borderless": false,
		"resolution": "1920x1080",
		"vsync": true
	},
	"audio": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.8
	},
	"input": {
		"actions": {}
	},
	"leaderboard": {
		"base_url": "",
		"enabled": true,
		"hmac_key": "",
		"max_score": 100000000,
		"timeout_secs": 8.0
	},
	"game": {}
}

var _config: Dictionary = DEFAULT_CONFIG.duplicate(true)
var _template_assets_config: Dictionary = {}
var _template_input_actions: Dictionary = {}
var _template_audio_registry: Dictionary = {}


func _ready() -> void:
	load_config()
	_load_template_configs()


func load_config() -> void:
	var user_path := ProjectSettings.globalize_path("user://")
	DirAccess.make_dir_recursive_absolute(user_path)
	var cf := ConfigFile.new()
	var err := cf.load(ProjectSettings.globalize_path(CONFIG_PATH))
	if err != OK:
		err = cf.load(ProjectSettings.globalize_path(CONFIG_PATH_FALLBACK))
	if err == OK:
		_config = cf.get_value("config", "data", DEFAULT_CONFIG.duplicate(true))
	else:
		_config = DEFAULT_CONFIG.duplicate(true)
	_merge_missing(_config, DEFAULT_CONFIG)
	save_config()
	_apply_display_settings()
	_apply_audio_settings()
	_apply_input_settings()


func save_config() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://"))
	var cf := ConfigFile.new()
	cf.set_value("config", "data", _config)
	var err := cf.save(ProjectSettings.globalize_path(CONFIG_PATH))
	if err != OK:
		push_warning("ConfigManager: failed to save config (user:// unavailable), settings not persisted.")
		return


func get_setting(category: String, key: String, default_value = null):
	var cat: Dictionary = _config.get(category, {})
	return cat.get(key, default_value)


func set_setting(category: String, key: String, value, autosave := true) -> void:
	if not _config.has(category) or typeof(_config[category]) != TYPE_DICTIONARY:
		_config[category] = {}
	_config[category][key] = value
	if autosave:
		save_config()
	_apply_category(category)
	if Engine.has_singleton("EventBus"):
		var bus = Engine.get_singleton("EventBus")
		bus.emit("config_changed", {"category": category, "key": key, "value": value})


func get_full_config() -> Dictionary:
	return _config.duplicate(true)


func get_template_assets_config() -> Dictionary:
	return _template_assets_config.duplicate(true)


func get_template_input_actions() -> Dictionary:
	return _template_input_actions.get("actions", {}).duplicate(true)


func get_template_audio_registry() -> Dictionary:
	return _template_audio_registry.duplicate(true)


func apply_display_settings_from_dict(display: Dictionary) -> void:
	_apply_display_settings_internal(display)


func _merge_missing(target: Dictionary, defaults: Dictionary) -> void:
	for key in defaults.keys():
		if not target.has(key):
			target[key] = defaults[key]
			continue
		if typeof(defaults[key]) == TYPE_DICTIONARY and typeof(target[key]) == TYPE_DICTIONARY:
			_merge_missing(target[key], defaults[key])


func _apply_category(category: String) -> void:
	match category:
		"display":
			_apply_display_settings()
		"audio":
			_apply_audio_settings()
		"input":
			_apply_input_settings()
		_:
			pass


func _apply_display_settings() -> void:
	var display: Dictionary = _config.get("display", {})
	_apply_display_settings_internal(display)


func _apply_display_settings_internal(display: Dictionary) -> void:
	if not display:
		return
	var window: int = 0
	if display.has("fullscreen"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if display["fullscreen"] else DisplayServer.WINDOW_MODE_WINDOWED, window)
	if display.has("borderless"):
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, display["borderless"], window)
	if display.has("vsync"):
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if display["vsync"] else DisplayServer.VSYNC_DISABLED)
	if display.has("resolution") and typeof(display["resolution"]) == TYPE_STRING:
		var parts: PackedStringArray = display["resolution"].split("x")
		if parts.size() == 2:
			var w: int = int(parts[0])
			var h: int = int(parts[1])
			if w > 0 and h > 0:
				DisplayServer.window_set_size(Vector2i(w, h), window)


func _apply_audio_settings() -> void:
	var audio: Dictionary = _config.get("audio", {})
	if not audio:
		return
	if Engine.has_singleton("AudioManager"):
		var audio_manager = Engine.get_singleton("AudioManager")
		audio_manager.update_volumes(audio)


func _apply_input_settings() -> void:
	if Engine.has_singleton("InputManager"):
		var input_manager = Engine.get_singleton("InputManager")
		input_manager.apply_bindings_from_config()


func _load_template_configs() -> void:
	_template_assets_config = _load_json_dict(_resolve_template_path(TEMPLATE_ASSETS_CONFIG_REL), {
		"company": {
			"name": "OneDayGames",
			"logo_path": "",
			"fallback_text": "OneDayGames",
			"footer": "© OneDayGames. All rights reserved."
		},
		"game": {
			"title": "OneDay Template",
			"logo_path": "",
			"fallback_text": "OneDay Template"
		},
		"legal": {
			"epilepsy_warning": "This game may contain flashing lights. Player discretion advised.",
			"mission": "OneDayGames builds games in around one man-day by leaning on AI for code, art, sound, and design.",
			"credits_text": "Created with the OneDayGames default template.",
			"footer": "© OneDayGames. All rights reserved."
		}
	})
	_template_input_actions = _load_json_dict(_resolve_template_path(TEMPLATE_INPUT_ACTIONS_REL), {"actions": {}})
	_template_audio_registry = _load_json_dict(_resolve_template_path(TEMPLATE_AUDIO_REGISTRY_REL), {"music": {}, "sfx": {}})


func _load_json_dict(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return fallback.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return fallback.duplicate(true)
	var text := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) == TYPE_DICTIONARY:
		return data
	return fallback.duplicate(true)


func _resolve_template_path(relative_path: String) -> String:
	var direct := "res://%s" % relative_path
	var template_path := "res://defaultTemplate/%s" % relative_path
	if FileAccess.file_exists(direct):
		return direct
	if FileAccess.file_exists(template_path):
		return template_path
	return direct
