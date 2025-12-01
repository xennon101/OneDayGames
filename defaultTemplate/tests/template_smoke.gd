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
