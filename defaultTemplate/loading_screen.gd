extends Control

@onready var company_logo_tex: TextureRect = $VBoxContainer/CompanyLogo
@onready var company_logo_text: Label = $VBoxContainer/CompanyLogoFallback
@onready var game_logo_tex: TextureRect = $VBoxContainer/GameLogo
@onready var game_logo_text: Label = $VBoxContainer/GameLogoFallback
@onready var status_label: Label = $VBoxContainer/Status
@onready var progress_bar: ProgressBar = $VBoxContainer/Progress
@onready var footer_label: Label = $Footer/LegalFooter


func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_apply_logo_config()
	_apply_footer()


func set_status_text(text: String) -> void:
	var label: Label = status_label if status_label else get_node_or_null("VBoxContainer/Status")
	if label:
		label.text = text


func set_progress(value: float) -> void:
	var bar: ProgressBar = progress_bar if progress_bar else get_node_or_null("VBoxContainer/Progress")
	if bar:
		bar.value = clamp(value, 0.0, 1.0)


func set_company_logo(texture: Texture2D, fallback_text: String = "") -> void:
	_set_logo(company_logo_tex, company_logo_text, texture, fallback_text)


func set_game_logo(texture: Texture2D, fallback_text: String = "") -> void:
	_set_logo(game_logo_tex, game_logo_text, texture, fallback_text)


func set_footer(text: String) -> void:
	if footer_label:
		footer_label.text = text


func _apply_logo_config() -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg == null:
		_set_logo(company_logo_tex, company_logo_text, null, "OneDayGames")
		_set_logo(game_logo_tex, game_logo_text, null, "OneDay Template")
		return
	var assets: Dictionary = cfg.get_template_assets_config()
	var company_path: String = assets.get("company", {}).get("logo_path", "")
	var company_fallback: String = assets.get("company", {}).get("fallback_text", "OneDayGames")
	var game_path: String = assets.get("game", {}).get("logo_path", "")
	var game_fallback: String = assets.get("game", {}).get("fallback_text", "OneDay Template")
	var company_tex: Texture2D = _load_texture(company_path)
	var game_tex: Texture2D = _load_texture(game_path)
	_set_logo(company_logo_tex, company_logo_text, company_tex, company_fallback)
	_set_logo(game_logo_tex, game_logo_text, game_tex, game_fallback)


func _apply_footer() -> void:
	var cfg = _get_autoload("ConfigManager")
	if cfg == null:
		set_footer("© OneDayGames. All rights reserved.")
		return
	var assets: Dictionary = cfg.get_template_assets_config()
	var footer: String = assets.get("legal", {}).get("footer", "© OneDayGames. All rights reserved.")
	set_footer(footer)


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
