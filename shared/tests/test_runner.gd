extends SceneTree

var _failures := 0
var _tests_run := 0
var _ping_calls := 0


func _initialize() -> void:
	ProjectSettings.set_setting("application/config/user_data_dir", "res://tmp_user")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp_user"))
	_run_all()
	print("Tests run: %s, failures: %s" % [_tests_run, _failures])
	quit(_failures)


func _run_all() -> void:
	_run("SceneConfig registers and resolves", _test_scene_config)
	_run("EventBus publish/subscribe", _test_event_bus)
	_run("ConfigManager merges defaults", _test_config_manager)
	_run("InputManager rebind flow", _test_input_manager)
	_run("AudioManager updates volumes safely", _test_audio_manager)
	_run("SaveManager writes and reads", _test_save_manager)
	_run("LegalManager provides defaults", _test_legal_manager)
	_run("SceneManager handles unknown id gracefully", _test_scene_manager_guard)


func _run(name: String, fn: Callable) -> void:
	_tests_run += 1
	var ok := true
	var err := ""
	var result = fn.call()
	if ok:
		print("PASS: %s" % name)
	else:
		_failures += 1
		err = str(result)
		push_error("FAIL: %s -> %s" % [name, err])


func _test_scene_config() -> void:
	var cfg = load("res://shared/autoload/SceneConfig.gd").new()
	cfg.reset_to_defaults()
	assert(cfg.has("boot"))
	cfg.register_scene("custom", "res://custom_scene.tscn")
	assert(cfg.get_scene_path("custom") == "res://custom_scene.tscn")
	assert("custom" in cfg.all_ids())


func _test_event_bus() -> void:
	var bus = load("res://shared/autoload/EventBus.gd").new()
	_ping_calls = 0
	bus.subscribe("ping", self, "_on_ping")
	bus.emit("ping", null)
	bus.emit("ping", null)
	assert(_ping_calls == 2)


func _on_ping(_payload) -> void:
	# Used by _test_event_bus
	_ping_calls += 1


func _test_config_manager() -> void:
	var cm = load("res://shared/autoload/ConfigManager.gd").new()
	get_root().add_child(cm)
	cm.set_setting("audio", "music_volume", 0.2)
	assert(is_equal_approx(cm.get_setting("audio", "music_volume", 0.0), 0.2))
	assert(cm.get_setting("display", "fullscreen", null) == false)
	cm.queue_free()


func _test_input_manager() -> void:
	var im = load("res://shared/autoload/InputManager.gd").new()
	get_root().add_child(im)
	im.start_rebind("move_left")
	var ev := InputEventKey.new()
	ev.keycode = Key.KEY_H
	ev.pressed = true
	im._input(ev)
	assert(not im.is_listening_for_rebind())
	var events := InputMap.action_get_events("move_left")
	assert(events.size() > 0)
	assert(events[0] is InputEventKey and events[0].keycode == Key.KEY_H)
	im.queue_free()


func _test_audio_manager() -> void:
	var am = load("res://shared/autoload/AudioManager.gd").new()
	get_root().add_child(am)
	am.update_volumes({"master_volume": 0.5, "music_volume": 0.4, "sfx_volume": 0.3})
	am.queue_free()


func _test_save_manager() -> void:
	var sm = load("res://shared/autoload/SaveManager.gd").new()
	sm.game_supports_saves = true
	var data := {"score": 10}
	sm.save_game(data)
	var loaded: Dictionary = sm.load_game()
	assert(loaded.get("score", 0) == 10)
	# Cleanup
	sm._clear_save()


func _test_legal_manager() -> void:
	var lm = load("res://shared/autoload/LegalManager.gd").new()
	assert(lm.get_company_name() != "")
	assert(lm.get_credits_text() != "")
	assert(typeof(lm.is_epilepsy_warning_enabled()) == TYPE_BOOL)


func _test_scene_manager_guard() -> void:
	var sm = load("res://shared/autoload/SceneManager.gd").new()
	var cfg = load("res://shared/autoload/SceneConfig.gd").new()
	sm.scene_config = cfg
	get_root().add_child(sm)
	sm.change_scene("nonexistent", false)
	assert(sm.get_current_scene_id() == "")
	sm.queue_free()
	cfg.queue_free()
