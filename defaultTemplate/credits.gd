extends Control

@onready var company_logo_tex: TextureRect = $Center/Logos/CompanyLogo
@onready var company_logo_fallback: Label = $Center/Logos/CompanyLogoFallback
@onready var game_logo_tex: TextureRect = $Center/Logos/GameLogo
@onready var game_logo_fallback: Label = $Center/Logos/GameLogoFallback
@onready var mission_label: Label = $Center/Mission
@onready var footer_label: Label = $Footer/LegalFooter


func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_populate()
	$Center/BackButton.pressed.connect(_on_back_pressed)


func _populate() -> void:
	_apply_logos()
	_apply_footer()
	var lm = _get_autoload("LegalManager")
	if lm == null:
		var cfg = _get_autoload("ConfigManager")
		if cfg:
			var assets: Dictionary = cfg.get_template_assets_config()
			$Center/Company.text = assets.get("game", {}).get("title", "OneDay Template")
			$Center/Website.text = "https://example.com"
			$Center/CreditsText.text = assets.get("legal", {}).get("credits_text", "Created with OneDayGames.")
			$Center/Copy.text = assets.get("legal", {}).get("footer", "(c) OneDayGames. All rights reserved.")
			mission_label.text = assets.get("legal", {}).get("mission", mission_label.text)
		return
	$Center/Company.text = lm.get_credits_text()
	$Center/Website.text = lm.get_website_url()
	$Center/CreditsText.text = lm.get_credits_text()
	$Center/Copy.text = lm.get_copyright()
	mission_label.text = "OneDayGames builds games in around one man-day by leaning on AI for code, art, sound, and design."


func _on_back_pressed() -> void:
	_play_ui_click()
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.return_to_main_menu()


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
	var footer_text := "(c) OneDayGames. All rights reserved."
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
