extends Control

const RESOLUTIONS := ["1280x720", "1600x900", "1920x1080", "2560x1440"]

@onready var fullscreen_cb: CheckBox = $Center/Tabs/Display/DisplayVBox/Fullscreen
@onready var borderless_cb: CheckBox = $Center/Tabs/Display/DisplayVBox/Borderless
@onready var vsync_cb: CheckBox = $Center/Tabs/Display/DisplayVBox/VSync
@onready var resolution_opt: OptionButton = $Center/Tabs/Display/DisplayVBox/ResolutionHBox/Resolution
@onready var keybinds_container: VBoxContainer = $Center/Tabs/Keybinds/KeybindsVBox
@onready var master_slider: HSlider = $Center/Tabs/Audio/AudioVBox/MasterHBox/MasterSlider
@onready var music_slider: HSlider = $Center/Tabs/Audio/AudioVBox/MusicHBox/MusicSlider
@onready var sfx_slider: HSlider = $Center/Tabs/Audio/AudioVBox/SfxHBox/SfxSlider
var _action_buttons: Dictionary = {}
var _input_manager: Object = null


func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_populate_resolution_options()
	_load_display_settings()
	_load_audio_settings()
	_build_keybinds()
	fullscreen_cb.toggled.connect(_on_fullscreen_toggled)
	borderless_cb.toggled.connect(_on_borderless_toggled)
	vsync_cb.toggled.connect(_on_vsync_toggled)
	resolution_opt.item_selected.connect(_on_resolution_selected)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	$Center/BackButton.pressed.connect(_on_back_pressed)
	_input_manager = _get_autoload("InputManager")
	if _input_manager:
		_input_manager.rebind_finished.connect(_on_rebind_finished)
		_input_manager.rebind_cancelled.connect(_on_rebind_cancelled)


func _populate_resolution_options() -> void:
	resolution_opt.clear()
	for res in RESOLUTIONS:
		resolution_opt.add_item(res)


func _load_display_settings() -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg == null:
		return
	fullscreen_cb.button_pressed = cfg.get_setting("display", "fullscreen", false)
	borderless_cb.button_pressed = cfg.get_setting("display", "borderless", false)
	vsync_cb.button_pressed = cfg.get_setting("display", "vsync", true)
	var current_res: String = cfg.get_setting("display", "resolution", "1920x1080")
	for i in RESOLUTIONS.size():
		if RESOLUTIONS[i] == current_res:
			resolution_opt.select(i)
			break


func _load_audio_settings() -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg == null:
		return
	master_slider.value = cfg.get_setting("audio", "master_volume", 1.0)
	music_slider.value = cfg.get_setting("audio", "music_volume", 0.8)
	sfx_slider.value = cfg.get_setting("audio", "sfx_volume", 0.8)


func _build_keybinds() -> void:
	for child in keybinds_container.get_children():
		child.queue_free()
	if _input_manager == null:
		_input_manager = _get_autoload("InputManager")
	if _input_manager == null:
		return
	_action_buttons.clear()
	for action_name in _input_manager.get_default_actions().keys():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.custom_minimum_size.y = 28
		var label := Label.new()
		label.text = action_name
		var button := Button.new()
		button.name = action_name
		button.text = _event_to_text(InputMap.action_get_events(action_name))
		button.pressed.connect(func():
			button.text = "Press key..."
			_input_manager.start_rebind(action_name)
		)
		row.add_child(label)
		row.add_child(button)
		keybinds_container.add_child(row)
		_action_buttons[action_name] = button


func _on_fullscreen_toggled(pressed: bool) -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.set_setting("display", "fullscreen", pressed)


func _on_borderless_toggled(pressed: bool) -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.set_setting("display", "borderless", pressed)


func _on_vsync_toggled(pressed: bool) -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.set_setting("display", "vsync", pressed)


func _on_resolution_selected(index: int) -> void:
	if index < 0 or index >= RESOLUTIONS.size():
		return
	var value: String = RESOLUTIONS[index]
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.set_setting("display", "resolution", value)


func _on_master_changed(value: float) -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.set_setting("audio", "master_volume", value)


func _on_music_changed(value: float) -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.set_setting("audio", "music_volume", value)


func _on_sfx_changed(value: float) -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.set_setting("audio", "sfx_volume", value)


func _on_back_pressed() -> void:
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.return_to_main_menu()


func _on_rebind_finished(action_name: String, _event: InputEvent) -> void:
	_update_binding_button(action_name)


func _on_rebind_cancelled(action_name: String) -> void:
	_update_binding_button(action_name)


func _update_binding_button(action_name: String) -> void:
	var button: Button = _action_buttons.get(action_name)
	if button:
		button.text = _event_to_text(InputMap.action_get_events(action_name))


func _event_to_text(events: Array) -> String:
	if events.is_empty():
		return "Unbound"
	var ev: InputEvent = events[0]
	if ev is InputEventKey:
		return OS.get_keycode_string(ev.keycode)
	if ev is InputEventMouseButton:
		return "Mouse %s" % ev.button_index
	return "Bound"


func _get_autoload(name: String) -> Object:
	var root := get_tree().get_root()
	if root.has_node(name):
		return root.get_node(name)
	if Engine.has_singleton(name):
		return Engine.get_singleton(name)
	return null
