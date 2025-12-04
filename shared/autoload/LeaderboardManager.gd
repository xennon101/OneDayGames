extends Node

const ENDPOINT_SUBMIT := "/leaderboard/submit"
const ENDPOINT_TOP := "/leaderboard/top"
const ENDPOINT_PLAYER := "/leaderboard/player"
const ENDPOINT_TOP_WITH_PLAYER := "/leaderboard/top-with-player"

const DEFAULT_LIMIT := 10
const HEADER_SIGNATURE := "X-Signature"

var _http_parent: Node


func _ready() -> void:
	_http_parent = self


func submit_score(game_id: String, score: int, player_name: String = "", callback: Callable = Callable()) -> void:
	if not _is_enabled():
		_safe_callback(callback, {"status": "disabled"}, "")
		return
	if score < 0 or score > _max_score():
		_safe_callback(callback, {}, "invalid_score")
		return
	var player_id := _get_player_id()
	if player_id.is_empty():
		_safe_callback(callback, {}, "missing_player_id")
		return
	var payload := {
		"game_id": game_id,
		"player_id": player_id,
		"player_name": player_name,
		"score": score,
		"nonce": _generate_nonce(),
		"timestamp": int(Time.get_unix_time_from_system())
	}
	var body := _canonicalize_json(payload)
	var signature := _sign(body)
	if signature.is_empty():
		_safe_callback(callback, {}, "missing_signature")
		return
	_perform_request(
		HTTPClient.METHOD_POST,
		ENDPOINT_SUBMIT,
		body,
		signature,
		callback,
		true
	)


func fetch_top(game_id: String, limit: int = DEFAULT_LIMIT, callback: Callable = Callable()) -> void:
	if not _is_enabled():
		_safe_callback(callback, [], "")
		return
	var params := {
		"game_id": game_id,
		"limit": clamp(limit, 1, 100)
	}
	var query := _canonicalize_query(params)
	var signature := _sign(query)
	if signature.is_empty():
		_safe_callback(callback, [], "missing_signature")
		return
	_perform_request(
		HTTPClient.METHOD_GET,
		"%s?%s" % [ENDPOINT_TOP, query],
		"",
		signature,
		func(result, err):
			if err != "":
				_safe_callback(callback, [], err)
				return
			var entries := result.get("entries", [])
			_safe_callback(callback, entries, "")
	)


func fetch_player(game_id: String, callback: Callable = Callable()) -> void:
	if not _is_enabled():
		_safe_callback(callback, {"has_score": false}, "")
		return
	var player_id := _get_player_id()
	if player_id.is_empty():
		_safe_callback(callback, {"has_score": false}, "missing_player_id")
		return
	var params := {
		"game_id": game_id,
		"player_id": player_id
	}
	var query := _canonicalize_query(params)
	var signature := _sign(query)
	if signature.is_empty():
		_safe_callback(callback, {"has_score": false}, "missing_signature")
		return
	_perform_request(
		HTTPClient.METHOD_GET,
		"%s?%s" % [ENDPOINT_PLAYER, query],
		"",
		signature,
		func(result, err):
			if err != "":
				_safe_callback(callback, {"has_score": false}, err)
				return
			_safe_callback(callback, result, "")
	)


func fetch_top_with_player(game_id: String, limit: int = DEFAULT_LIMIT, callback: Callable = Callable()) -> void:
	if not _is_enabled():
		_safe_callback(callback, {"entries": [], "player": {"has_score": false}}, "")
		return
	var player_id := _get_player_id()
	if player_id.is_empty():
		_safe_callback(callback, {"entries": [], "player": {"has_score": false}}, "missing_player_id")
		return
	var params := {
		"game_id": game_id,
		"player_id": player_id,
		"limit": clamp(limit, 1, 100)
	}
	var query := _canonicalize_query(params)
	var signature := _sign(query)
	if signature.is_empty():
		_safe_callback(callback, {"entries": [], "player": {"has_score": false}}, "missing_signature")
		return
	_perform_request(
		HTTPClient.METHOD_GET,
		"%s?%s" % [ENDPOINT_TOP_WITH_PLAYER, query],
		"",
		signature,
		func(result, err):
			if err != "":
				_safe_callback(callback, {"entries": [], "player": {"has_score": false}}, err)
				return
			_safe_callback(callback, result, "")
	)


func _perform_request(method: HTTPClient.Method, path: String, body: String, signature: String, callback: Callable, is_json_body := false) -> void:
	var base_url := _base_url()
	if base_url.is_empty():
		_safe_callback(callback, {}, "missing_base_url")
		return
	var request := HTTPRequest.new()
	request.timeout = _timeout_secs()
	_http_parent.add_child(request)
	var url := "%s%s" % [base_url.rstrip("/"), path]
	var headers: PackedStringArray = [HEADER_SIGNATURE + ": " + signature]
	if is_json_body:
		headers.append("Content-Type: application/json")
	var err := request.request(url, headers, method, body)
	if err != OK:
		request.queue_free()
		_safe_callback(callback, {}, "request_failed")
		return
	request.request_completed.connect(func(result: int, response_code: int, _headers: PackedStringArray, response_body: PackedByteArray):
		request.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS:
			_safe_callback(callback, {}, "network_error")
			return
		if response_code < 200 or response_code >= 300:
			_safe_callback(callback, {}, "http_%d" % response_code)
			return
		var text := response_body.get_string_from_utf8()
		var parsed := JSON.parse_string(text)
		if typeof(parsed) == TYPE_DICTIONARY:
			_safe_callback(callback, parsed, "")
		else:
			_safe_callback(callback, {}, "invalid_response")
	)


func _sign(payload: String) -> String:
	var secret := _hmac_secret()
	if secret.is_empty():
		return ""
	var crypto := Crypto.new()
	var hash: PackedByteArray = crypto.hmac_sha256(secret.to_utf8_buffer(), payload.to_utf8_buffer())
	return hash.hex_encode()


func _canonicalize_json(data) -> String:
	return JSON.stringify(_sort_value(data))


func _sort_value(value):
	match typeof(value):
		TYPE_DICTIONARY:
			var ordered := {}
			var keys := value.keys()
			keys.sort()
			for key in keys:
				ordered[key] = _sort_value(value[key])
			return ordered
		TYPE_ARRAY:
			var arr: Array = []
			for item in value:
				arr.append(_sort_value(item))
			return arr
		_:
			return value


func _canonicalize_query(params: Dictionary) -> String:
	var keys := params.keys()
	keys.sort()
	var parts: PackedStringArray = []
	for key in keys:
		var value = params[key]
		if value == null:
			continue
		parts.append("%s=%s" % [String(key).uri_encode(), String(value).uri_encode()])
	return "&".join(parts)


func _base_url() -> String:
	var config_manager = _get_config_manager()
	if config_manager:
		return str(config_manager.get_setting("leaderboard", "base_url", ""))
	return ""


func _is_enabled() -> bool:
	var config_manager = _get_config_manager()
	if config_manager:
		return bool(config_manager.get_setting("leaderboard", "enabled", true))
	return true


func _max_score() -> int:
	var config_manager = _get_config_manager()
	if config_manager:
		return int(config_manager.get_setting("leaderboard", "max_score", 2147483647))
	return 2147483647


func _timeout_secs() -> float:
	var config_manager = _get_config_manager()
	if config_manager:
		return float(config_manager.get_setting("leaderboard", "timeout_secs", 8.0))
	return 8.0


func _hmac_secret() -> String:
	var config_manager = _get_config_manager()
	if config_manager:
		return str(config_manager.get_setting("leaderboard", "hmac_key", ""))
	return ""


func _get_config_manager():
	return Engine.get_singleton("ConfigManager") if Engine.has_singleton("ConfigManager") else null


func _get_player_id() -> String:
	if Engine.has_singleton("PlayerIdentityManager"):
		var mgr = Engine.get_singleton("PlayerIdentityManager")
		return mgr.get_player_id()
	return ""


func _generate_nonce() -> String:
	return _generate_uuid_v4()


func _generate_uuid_v4() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var bytes := []
	for i in 16:
		bytes.append(rng.randi_range(0, 255))
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


func _safe_callback(callback: Callable, result, error: String) -> void:
	if callback.is_valid():
		callback.call(result, error)
