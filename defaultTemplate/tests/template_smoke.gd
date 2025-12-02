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
	if status != "Loading test" or not is_equal_approx(progress, 0.5):
		push_error("Loading screen status/progress mismatch")
		return false
	inst.queue_free()
	return true


func _test_settings_apply_ui() -> bool:
	var packed := ResourceLoader.load("res://settings_menu.tscn")
	var inst: Control = packed.instantiate()
	get_root().add_child(inst)
	inst.call("_populate_resolution_options")
	assert(inst.has_node("Center/Tabs/Display/DisplayVBox/ApplyButton"))
	assert(inst.has_node("Center/Tabs/Display/DisplayVBox/ApplyConfirm"))
	assert(inst.has_node("Footer/LegalFooter"))
	var options: OptionButton = inst.get_node("Center/Tabs/Display/DisplayVBox/ResolutionHBox/Resolution")
	if options.item_count <= 0:
		push_error("Resolution list is empty")
		return false
	inst.queue_free()
	return true


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
	get_root().remove_child(im)
	get_root().remove_child(cfg)
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
	if not (footer_label.text == footer or footer.is_empty()):
		push_error("Footer text mismatch: %s vs %s" % [footer_label.text, footer])
		return false
	inst.queue_free()
	get_root().remove_child(cfg)
	cfg.queue_free()
	return true
