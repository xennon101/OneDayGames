extends Control

@onready var start_button: Button = $Center/Menu/StartButton
@onready var load_button: Button = $Center/Menu/LoadButton
@onready var settings_button: Button = $Center/Menu/SettingsButton
@onready var credits_button: Button = $Center/Menu/CreditsButton
@onready var exit_button: Button = $Center/Menu/ExitButton
@onready var company_logo_tex: TextureRect = $Center/Logos/CompanyLogo
@onready var company_logo_fallback: Label = $Center/Logos/CompanyLogoFallback
@onready var game_logo_tex: TextureRect = $Center/Logos/GameLogo
@onready var game_logo_fallback: Label = $Center/Logos/GameLogoFallback
@onready var footer_label: Label = $Footer/LegalFooter


func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_apply_logos()
	_apply_footer()
	_refresh_load_button()
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _refresh_load_button() -> void:
	var can_load := false
	var save_manager = _get_autoload("SaveManager")
	if save_manager:
		can_load = save_manager.game_supports_saves and save_manager.has_save()
	load_button.disabled = not can_load


func _on_start_pressed() -> void:
	_play_ui_click()
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.change_scene("gameplay")


func _on_load_pressed() -> void:
	if load_button.disabled:
		return
	_play_ui_click()
	var save_manager = _get_autoload("SaveManager")
	if save_manager:
		var data: Dictionary = save_manager.load_game()
		# Real games should consume data; placeholder just enters gameplay.
		var sm = _get_autoload("SceneManager")
		if sm:
			sm.change_scene("gameplay")


func _on_settings_pressed() -> void:
	_play_ui_click()
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.change_scene("settings")


func _on_credits_pressed() -> void:
	_play_ui_click()
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.change_scene("credits")


func _on_exit_pressed() -> void:
	_play_ui_click()
	var bus = _get_autoload("EventBus")
	if bus:
		bus.emit("request_quit_game")
	else:
		var sm = _get_autoload("SceneManager")
		if sm:
			sm.quit()


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
	var root := get_tree().get_root()
	if root.has_node(name):
		return root.get_node(name)
	if Engine.has_singleton(name):
		return Engine.get_singleton(name)
	return null
