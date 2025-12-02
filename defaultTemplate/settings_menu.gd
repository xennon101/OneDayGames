extends Control

@onready var fullscreen_cb: CheckBox = $Center/Tabs/Display/DisplayVBox/Fullscreen
@onready var borderless_cb: CheckBox = $Center/Tabs/Display/DisplayVBox/Borderless
@onready var vsync_cb: CheckBox = $Center/Tabs/Display/DisplayVBox/VSync
@onready var resolution_opt: OptionButton = $Center/Tabs/Display/DisplayVBox/ResolutionHBox/Resolution
@onready var apply_button: Button = $Center/Tabs/Display/DisplayVBox/ApplyButton
@onready var confirm_popup: ConfirmationDialog = $Center/Tabs/Display/DisplayVBox/ApplyConfirm
@onready var confirm_label: Label = $Center/Tabs/Display/DisplayVBox/ApplyConfirm/Label
@onready var confirm_timer: Timer = $Center/Tabs/Display/DisplayVBox/ApplyConfirm/RevertTimer
@onready var confirm_tick: Timer = $Center/Tabs/Display/DisplayVBox/ApplyConfirm/CountdownTick
@onready var keybinds_container: VBoxContainer = $Center/Tabs/Keybinds/KeybindsVBox
@onready var master_slider: HSlider = $Center/Tabs/Audio/AudioVBox/MasterHBox/MasterSlider
@onready var music_slider: HSlider = $Center/Tabs/Audio/AudioVBox/MusicHBox/MusicSlider
@onready var sfx_slider: HSlider = $Center/Tabs/Audio/AudioVBox/SfxHBox/SfxSlider
@onready var game_settings_container: VBoxContainer = $Center/Tabs/Game/GameVBox
@onready var footer_label: Label = $Footer/LegalFooter
@onready var company_logo_tex: TextureRect = $Center/Header/CompanyLogo
@onready var company_logo_fallback: Label = $Center/Header/CompanyLogoFallback
@onready var game_logo_tex: TextureRect = $Center/Header/GameLogo
@onready var game_logo_fallback: Label = $Center/Header/GameLogoFallback
var _action_buttons: Dictionary = {}
var _input_manager: Object = null
var _staged_display: Dictionary = {}
var _previous_display: Dictionary = {}
var _apply_timeout_seconds: float = 15.0
var _countdown_remaining: float = 0.0
var _listening_action: String = ""


func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_apply_logos()
	_apply_footer()
	_populate_resolution_options()
	_load_display_settings()
	_load_audio_settings()
	_build_keybinds()
	if resolution_opt and resolution_opt.item_count == 0:
		_populate_resolution_options()
	fullscreen_cb.toggled.connect(_on_fullscreen_toggled)
	borderless_cb.toggled.connect(_on_borderless_toggled)
	vsync_cb.toggled.connect(_on_vsync_toggled)
	resolution_opt.item_selected.connect(_on_resolution_selected)
	apply_button.pressed.connect(_on_apply_pressed)
	confirm_popup.confirmed.connect(_on_keep_pressed)
	confirm_popup.canceled.connect(_on_revert_pressed)
	confirm_timer.timeout.connect(_on_revert_timeout)
	confirm_tick.timeout.connect(_on_countdown_tick)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	$Center/BackButton.pressed.connect(_on_back_pressed)
	_input_manager = _get_autoload("InputManager")
	if _input_manager:
		_input_manager.rebind_finished.connect(_on_rebind_finished)
		_input_manager.rebind_cancelled.connect(_on_rebind_cancelled)


func _populate_resolution_options() -> void:
	if resolution_opt == null:
		resolution_opt = get_node_or_null("Center/Tabs/Display/DisplayVBox/ResolutionHBox/Resolution")
		if resolution_opt == null:
			return
	resolution_opt.clear()
	var resolutions: PackedStringArray = _get_supported_resolutions()
	resolutions.append_array(["1280x720", "1600x900", "1920x1080", "2560x1440"])
	var unique_res := PackedStringArray()
	for res in resolutions:
		if not unique_res.has(res):
			unique_res.append(res)
	for res in unique_res:
		resolution_opt.add_item(res)


func _load_display_settings() -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg == null:
		return
	_staged_display = cfg.get_full_config().get("display", {}).duplicate(true)
	fullscreen_cb.button_pressed = _staged_display.get("fullscreen", false)
	borderless_cb.button_pressed = _staged_display.get("borderless", false)
	vsync_cb.button_pressed = _staged_display.get("vsync", true)
	var current_res: String = _staged_display.get("resolution", _get_default_resolution())
	var res_list := _get_supported_resolutions()
	for i in res_list.size():
		if res_list[i] == current_res:
			resolution_opt.select(i)
			break


func _load_audio_settings() -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg == null:
		return
	master_slider.value = cfg.get_setting("audio", "master_volume", 1.0) * 100.0
	music_slider.value = cfg.get_setting("audio", "music_volume", 0.8) * 100.0
	sfx_slider.value = cfg.get_setting("audio", "sfx_volume", 0.8) * 100.0


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
			_set_listening_button(action_name, button, true)
			_input_manager.start_rebind(action_name)
		)
		row.add_child(label)
		row.add_child(button)
		keybinds_container.add_child(row)
		_action_buttons[action_name] = button


func _on_fullscreen_toggled(pressed: bool) -> void:
	_staged_display["fullscreen"] = pressed


func _on_borderless_toggled(pressed: bool) -> void:
	_staged_display["borderless"] = pressed


func _on_vsync_toggled(pressed: bool) -> void:
	_staged_display["vsync"] = pressed


func _on_resolution_selected(index: int) -> void:
	var res_list := _get_supported_resolutions()
	if index < 0 or index >= res_list.size():
		return
	var value: String = res_list[index]
	_staged_display["resolution"] = value


func _on_apply_pressed() -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg == null:
		return
	_previous_display = cfg.get_full_config().get("display", {}).duplicate(true)
	var new_settings := _collect_display_settings()
	_staged_display = new_settings.duplicate(true)
	cfg.apply_display_settings_from_dict(new_settings)
	_start_revert_countdown()


func _on_master_changed(value: float) -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.set_setting("audio", "master_volume", value / 100.0)
	_show_slider_value(master_slider, value)


func _on_music_changed(value: float) -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.set_setting("audio", "music_volume", value / 100.0)
	_show_slider_value(music_slider, value)


func _on_sfx_changed(value: float) -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.set_setting("audio", "sfx_volume", value / 100.0)
	_show_slider_value(sfx_slider, value)


func _on_back_pressed() -> void:
	_play_ui_click()
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.return_to_main_menu()


func _on_rebind_finished(action_name: String, _event: InputEvent) -> void:
	_set_listening_button(action_name, _action_buttons.get(action_name), false)
	_update_binding_button(action_name)


func _on_rebind_cancelled(action_name: String) -> void:
	_set_listening_button(action_name, _action_buttons.get(action_name), false)
	_update_binding_button(action_name)


func _update_binding_button(action_name: String) -> void:
	var button: Button = _action_buttons.get(action_name)
	if button:
		button.text = _event_to_text(InputMap.action_get_events(action_name))


func _on_keep_pressed() -> void:
	confirm_timer.stop()
	confirm_tick.stop()
	_countdown_remaining = 0.0
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		for key in _staged_display.keys():
			cfg.set_setting("display", key, _staged_display[key])
	confirm_popup.hide()


func _on_revert_pressed() -> void:
	confirm_timer.stop()
	_revert_display_settings()
	confirm_popup.hide()


func _on_revert_timeout() -> void:
	_revert_display_settings()
	confirm_popup.hide()


func _event_to_text(events: Array) -> String:
	if events.is_empty():
		return "Unbound"
	var ev: InputEvent = events[0]
	if ev is InputEventKey:
		return OS.get_keycode_string(ev.keycode)
	if ev is InputEventMouseButton:
		return "Mouse %s" % ev.button_index
	return "Bound"


func get_game_settings_container() -> VBoxContainer:
	return game_settings_container


func _collect_display_settings() -> Dictionary:
	var res_list: PackedStringArray = _get_supported_resolutions()
	var res_index := resolution_opt.selected
	var res_value: String = _staged_display.get("resolution", _get_default_resolution())
	if res_index >= 0 and res_index < res_list.size():
		res_value = res_list[res_index]
	return {
		"fullscreen": fullscreen_cb.button_pressed,
		"borderless": borderless_cb.button_pressed,
		"vsync": vsync_cb.button_pressed,
		"resolution": res_value
	}


func _get_supported_resolutions() -> PackedStringArray:
	var resolutions: PackedStringArray = []
	var screen_count := DisplayServer.get_screen_count()
	for i in range(screen_count):
		var size: Vector2i = DisplayServer.screen_get_size(i)
		resolutions.append("%sx%s" % [size.x, size.y])
	if resolutions.is_empty():
		resolutions = ["1280x720", "1600x900", "1920x1080", "2560x1440"]
	return resolutions.duplicate()


func _get_default_resolution() -> String:
	var size := DisplayServer.window_get_size()
	return "%sx%s" % [size.x, size.y]


func _start_revert_countdown() -> void:
	_countdown_remaining = _apply_timeout_seconds
	_update_confirm_label()
	confirm_popup.popup_centered()
	confirm_timer.wait_time = _apply_timeout_seconds
	confirm_timer.start()
	confirm_tick.wait_time = 1.0
	confirm_tick.start()


func _revert_display_settings() -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		cfg.apply_display_settings_from_dict(_previous_display)
		for key in _previous_display.keys():
			cfg.set_setting("display", key, _previous_display[key])
	_load_display_settings()
	confirm_tick.stop()
	_countdown_remaining = 0.0


func _apply_logos() -> void:
	var cfg = _get_autoload("ConfigManager")
	var assets: Dictionary = {} if cfg == null else cfg.get_template_assets_config()
	var company_path: String = assets.get("company", {}).get("logo_path", "")
	var company_fallback: String = assets.get("company", {}).get("fallback_text", "OneDayGames")
	var game_path: String = assets.get("game", {}).get("logo_path", "")
	var game_fallback: String = assets.get("game", {}).get("fallback_text", "OneDay Template")
	var company_tex := _load_texture(company_path)
	var game_tex := _load_texture(game_path)
	_set_logo(company_logo_tex, company_logo_fallback, company_tex, company_fallback)
	_set_logo(game_logo_tex, game_logo_fallback, game_tex, game_fallback)


func _apply_footer() -> void:
	var footer_text := "© OneDayGames. All rights reserved."
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		var assets: Dictionary = cfg.get_template_assets_config()
		footer_text = assets.get("legal", {}).get("footer", footer_text)
	if footer_label:
		footer_label.text = footer_text


func _play_ui_click() -> void:
	var audio = _get_autoload("AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("ui_click")


func _show_slider_value(slider: HSlider, value: float) -> void:
	if slider == null:
		return
	slider.hint_tooltip = str(int(round(value)))


func _set_logo(tex_node: TextureRect, label_node: Label, texture: Texture2D, fallback_text: String) -> void:
	if tex_node == null or label_node == null:
		return
	if texture:
		tex_node.texture = texture
		tex_node.visible = true
		label_node.visible = false
	else:
		tex_node.texture = null
		tex_node.visible = false
		label_node.visible = true
		label_node.text = fallback_text


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		return null
	var tex := ResourceLoader.load(path)
	return tex if tex is Texture2D else null


func _get_autoload(name: String) -> Object:
	var tree := get_tree()
	if tree:
		var root := tree.get_root()
		if root and root.has_node(name):
			return root.get_node(name)
	if Engine.has_singleton(name):
		return Engine.get_singleton(name)
	return null


func _update_confirm_label() -> void:
	var remaining := int(round(_countdown_remaining))
	if remaining < 0:
		remaining = 0
	confirm_label.text = "Keep these display settings?\nReverting in %s..." % remaining


func _on_countdown_tick() -> void:
	_countdown_remaining -= 1.0
	_update_confirm_label()
	if _countdown_remaining <= 0.0:
		confirm_tick.stop()


func _set_listening_button(action_name: String, button: Button, listening: bool) -> void:
	if button == null:
		return
	_listening_action = action_name if listening else ""
	button.disabled = listening
	if listening:
		button.release_focus()
