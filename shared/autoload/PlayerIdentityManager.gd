extends Node

const CONFIG_CATEGORY := "game"
const CONFIG_KEY := "player_id"

var _player_id: String = ""


func _ready() -> void:
	_ensure_player_id()


func get_player_id() -> String:
	if _player_id.is_empty():
		_ensure_player_id()
	return _player_id


func reset_player_id() -> void:
	_player_id = _generate_uuid_v4()
	_persist_player_id()


func _ensure_player_id() -> void:
	if not _player_id.is_empty():
		return
	var config_manager = _get_config_manager()
	if config_manager:
		var existing: String = str(config_manager.get_setting(CONFIG_CATEGORY, CONFIG_KEY, ""))
		if not existing.is_empty():
			_player_id = existing
			return
	_player_id = _generate_uuid_v4()
	_persist_player_id()


func _persist_player_id() -> void:
	var config_manager = _get_config_manager()
	if config_manager:
		config_manager.set_setting(CONFIG_CATEGORY, CONFIG_KEY, _player_id, true)


func _get_config_manager():
	return Engine.get_singleton("ConfigManager") if Engine.has_singleton("ConfigManager") else null


func _generate_uuid_v4() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var bytes := []
	for i in 16:
		bytes.append(rng.randi_range(0, 255))
	# Set version (0100xxxx) and variant (10xxxxxx)
	bytes[6] = (bytes[6] & 0x0F) | 0x40
	bytes[8] = (bytes[8] & 0x3F) | 0x80
	var parts := [
		_bytes_to_hex(bytes, 0, 4),
		_bytes_to_hex(bytes, 4, 2),
		_bytes_to_hex(bytes, 6, 2),
		_bytes_to_hex(bytes, 8, 2),
		_bytes_to_hex(bytes, 10, 6)
	]
	return parts.join("-")


func _bytes_to_hex(bytes: Array, start: int, length: int) -> String:
	var slice := bytes.slice(start, start + length)
	var hex_parts: PackedStringArray = []
	for b in slice:
		hex_parts.append("%02x" % int(b))
	return hex_parts.join("")
