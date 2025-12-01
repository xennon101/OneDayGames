extends Node

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const MASTER_BUS := "Master"

var _sfx_registry: Dictionary = {}
var _music_registry: Dictionary = {}
var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer


func _ready() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_b = AudioStreamPlayer.new()
	_music_player_a.bus = MUSIC_BUS
	_music_player_b.bus = MUSIC_BUS
	add_child(_music_player_a)
	add_child(_music_player_b)
	_active_music_player = _music_player_a


func register_sfx(id: String, stream: AudioStream) -> void:
	_sfx_registry[id] = stream


func register_music(id: String, stream: AudioStream) -> void:
	_music_registry[id] = stream


func play_sfx(id: String) -> void:
	var stream: AudioStream = _sfx_registry.get(id)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.bus = SFX_BUS
	player.stream = stream
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func play_music(id: String, crossfade_time := 0.5) -> void:
	var stream: AudioStream = _music_registry.get(id)
	if stream == null:
		return
	if _active_music_player.stream == stream:
		return
	var next_player := _music_player_b if _active_music_player == _music_player_a else _music_player_a
	next_player.stream = stream
	next_player.volume_db = -80.0
	next_player.play()
	_crossfade(_active_music_player, next_player, crossfade_time)
	_active_music_player = next_player


func stop_music(fade_out_time := 0.5) -> void:
	if _active_music_player == null:
		return
	var player := _active_music_player
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -80.0, fade_out_time)
	tween.tween_callback(Callable(player, "stop"))


func update_volumes(audio_config := {}) -> void:
	var cfg: Dictionary = audio_config
	if cfg.is_empty():
		if Engine.has_singleton("ConfigManager"):
			var config_manager = Engine.get_singleton("ConfigManager")
			cfg = config_manager.get_full_config().get("audio", {})
	var master: float = cfg.get("master_volume", 1.0)
	var music: float = cfg.get("music_volume", 0.8)
	var sfx: float = cfg.get("sfx_volume", 0.8)
	_set_bus_volume(MASTER_BUS, master)
	_set_bus_volume(MUSIC_BUS, music)
	_set_bus_volume(SFX_BUS, sfx)


func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clamp(linear, 0.0, 1.0)))


func _crossfade(from_player: AudioStreamPlayer, to_player: AudioStreamPlayer, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(to_player, "volume_db", 0.0, duration)
	tween.parallel().tween_property(from_player, "volume_db", -80.0, duration)
	tween.tween_callback(Callable(from_player, "stop"))
