extends SceneTree

var _failures := 0
var _tests_run := 0


func _initialize() -> void:
	_run_all()
	print("Template smoke tests run: %s, failures: %s" % [_tests_run, _failures])
	quit(_failures)


func _run_all() -> void:
	_run("Scripts load", _test_scripts_parse)
	_run("Scenes instantiate", _test_scenes_instantiate)
	_run("Main menu buttons exist", _test_main_menu_buttons)
	_run("Settings menu widgets exist", _test_settings_widgets)
	_run("Main menu logos/footer", _test_main_menu_logos)
	_run("Boot scene logos and footer", _test_boot_scene_logos)
	_run("Loading screen status/progress API", _test_loading_screen_status)
	_run("Settings apply/revert UI present", _test_settings_apply_ui)
	_run("Keybinds come from config", _test_keybinds_config)
	_run("Footer text matches config", _test_footer_from_config)
	_run("Enter key can be rebound", _test_rebind_enter_key)
	_run("Audio sliders show bounds and move", _test_audio_slider_labels)


func _run(name: String, fn: Callable) -> void:
	_tests_run += 1
	var ok := true
	var err := ""
	var result = fn.call()
	if result is bool and result == false:
		ok = false
	if ok:
		print("PASS: %s" % name)
	else:
		_failures += 1
		err = str(result)
		push_error("FAIL: %s -> %s" % [name, err])


func _test_scripts_parse() -> void:
	var scripts := [
		"res://main.gd",
		"res://boot.gd",
		"res://main_menu.gd",
		"res://settings_menu.gd",
		"res://credits.gd",
		"res://placeholder_game.gd"
	]
	for path in scripts:
		var res := ResourceLoader.load(path)
		assert(res != null)


func _test_scenes_instantiate() -> void:
	var scenes := [
		"res://main.tscn",
		"res://boot.tscn",
		"res://main_menu.tscn",
		"res://settings_menu.tscn",
		"res://credits.tscn",
		"res://placeholder_game.tscn",
		"res://loading_screen.tscn"
	]
	for path in scenes:
		var packed := ResourceLoader.load(path)
		assert(packed is PackedScene)
		var inst: Node = packed.instantiate()
		assert(inst != null)
		inst.queue_free()


func _test_main_menu_buttons() -> void:
	var packed := ResourceLoader.load("res://main_menu.tscn")
	var inst: Control = packed.instantiate()
	get_root().add_child(inst)
	assert(inst.has_node("Center/Menu/StartButton"))
	assert(inst.has_node("Center/Menu/LoadButton"))
	assert(inst.has_node("Center/Menu/SettingsButton"))
	assert(inst.has_node("Center/Menu/CreditsButton"))
	assert(inst.has_node("Center/Menu/ExitButton"))
	inst.queue_free()


func _test_settings_widgets() -> void:
	var packed := ResourceLoader.load("res://settings_menu.tscn")
	var inst: Control = packed.instantiate()
	get_root().add_child(inst)
	assert(inst.has_node("Center/Tabs/Display/DisplayVBox/Fullscreen"))
	assert(inst.has_node("Center/Tabs/Display/DisplayVBox/ResolutionHBox/Resolution"))
	assert(inst.has_node("Center/Tabs/Audio/AudioVBox/MasterHBox/MasterSlider"))
	assert(inst.has_node("Center/Tabs/Keybinds/KeybindsVBox"))
	inst.queue_free()


func _test_main_menu_logos() -> void:
	var packed := ResourceLoader.load("res://main_menu.tscn")
	var inst: Control = packed.instantiate()
	get_root().add_child(inst)
	assert(inst.has_node("Center/Logos/CompanyLogo"))
	assert(inst.has_node("Center/Logos/GameLogo"))
	assert(inst.has_node("Footer/LegalFooter"))
	inst.queue_free()


func _test_boot_scene_logos() -> void:
	var packed := ResourceLoader.load("res://boot.tscn")
	var inst: Control = packed.instantiate()
	get_root().add_child(inst)
	assert(inst.has_node("Center/CompanyLogo"))
	assert(inst.has_node("Center/CompanyLogoFallback"))
	assert(inst.has_node("Footer/LegalFooter"))
	inst.queue_free()


func _test_loading_screen_status() -> bool:
	var packed := ResourceLoader.load("res://loading_screen.tscn")
	var inst: Control = packed.instantiate()
	get_root().add_child(inst)
	inst.call("set_status_text", "Loading test")
	inst.call("set_progress", 0.5)
	var status: String = inst.get_node("VBoxContainer/Status").text
	var progress: float = inst.get_node("VBoxContainer/Progress").value
	inst.queue_free()
	return status == "Loading test" and is_equal_approx(progress, 0.5)


func _test_settings_apply_ui() -> bool:
	var packed := ResourceLoader.load("res://settings_menu.tscn")
	var inst: Control = packed.instantiate()
	get_root().add_child(inst)
	inst.call("_populate_resolution_options")
	var ok := inst.has_node("Center/Tabs/Display/DisplayVBox/ApplyButton")
	ok = ok and inst.has_node("Center/Tabs/Display/DisplayVBox/ApplyConfirm")
	ok = ok and inst.has_node("Footer/LegalFooter")
	var options: OptionButton = inst.get_node("Center/Tabs/Display/DisplayVBox/ResolutionHBox/Resolution")
	ok = ok and options.item_count > 0
	inst.queue_free()
	return ok


func _test_keybinds_config() -> void:
	var cfg: Node = load("res://shared/autoload/ConfigManager.gd").new()
	cfg.name = "ConfigManager"
	get_root().add_child(cfg)
	cfg._ready()
	var im: Node = load("res://shared/autoload/InputManager.gd").new()
	im.name = "InputManager"
	get_root().add_child(im)
	im._ready()
	var defaults: Dictionary = im.get_default_actions()
	assert(defaults.has("move_left"))
	assert(InputMap.has_action("move_left"))
	im.queue_free()
	cfg.queue_free()


func _test_footer_from_config() -> bool:
	var cfg: Node = load("res://shared/autoload/ConfigManager.gd").new()
	cfg.name = "ConfigManager"
	get_root().add_child(cfg)
	cfg._ready()
	var assets: Dictionary = cfg.get_template_assets_config()
	var footer: String = assets.get("legal", {}).get("footer", "")
	var packed := ResourceLoader.load("res://main_menu.tscn")
	var inst: Control = packed.instantiate()
	get_root().add_child(inst)
	var footer_label: Label = inst.get_node("Footer/LegalFooter")
	var ok := footer_label.text == footer or footer.is_empty()
	inst.queue_free()
	cfg.queue_free()
	return ok


func _test_rebind_enter_key() -> bool:
	var cfg: Node = load("res://shared/autoload/ConfigManager.gd").new()
	cfg.name = "ConfigManager"
	get_root().add_child(cfg)
	cfg._ready()
	var im: Node = load("res://shared/autoload/InputManager.gd").new()
	im.name = "InputManager"
	get_root().add_child(im)
	im._ready()
	im.start_rebind("move_left")
	var ev := InputEventKey.new()
	ev.keycode = Key.KEY_ENTER
	ev.pressed = true
	im._input(ev)
	var events := InputMap.action_get_events("move_left")
	im.queue_free()
	cfg.queue_free()
	return not events.is_empty() and events[0] is InputEventKey and events[0].keycode == Key.KEY_ENTER


func _test_audio_slider_labels() -> bool:
	var packed := ResourceLoader.load("res://settings_menu.tscn")
	var inst: Control = packed.instantiate()
	get_root().add_child(inst)
	var master_min: Label = inst.get_node("Center/Tabs/Audio/AudioVBox/MasterHBox/MasterMin")
	var master_max: Label = inst.get_node("Center/Tabs/Audio/AudioVBox/MasterHBox/MasterMax")
	var master_slider: HSlider = inst.get_node("Center/Tabs/Audio/AudioVBox/MasterHBox/MasterSlider")
	var music_min: Label = inst.get_node("Center/Tabs/Audio/AudioVBox/MusicHBox/MusicMin")
	var music_max: Label = inst.get_node("Center/Tabs/Audio/AudioVBox/MusicHBox/MusicMax")
	var music_slider: HSlider = inst.get_node("Center/Tabs/Audio/AudioVBox/MusicHBox/MusicSlider")
	var sfx_min: Label = inst.get_node("Center/Tabs/Audio/AudioVBox/SfxHBox/SfxMin")
	var sfx_max: Label = inst.get_node("Center/Tabs/Audio/AudioVBox/SfxHBox/SfxMax")
	var sfx_slider: HSlider = inst.get_node("Center/Tabs/Audio/AudioVBox/SfxHBox/SfxSlider")
	var ok := master_min.text == "0" and master_max.text == "100"
	ok = ok and music_min.text == "0" and music_max.text == "100"
	ok = ok and sfx_min.text == "0" and sfx_max.text == "100"
	ok = ok and master_slider.min_value == 0.0 and master_slider.max_value == 100.0
	ok = ok and music_slider.min_value == 0.0 and music_slider.max_value == 100.0
	ok = ok and sfx_slider.min_value == 0.0 and sfx_slider.max_value == 100.0
	inst.queue_free()
	return ok
