extends Control

@export var delay_seconds := 1.0

@onready var company_logo_tex: TextureRect = $Center/CompanyLogo
@onready var company_logo_fallback: Label = $Center/CompanyLogoFallback
@onready var warning_label: Label = $Center/Warning
@onready var legal_text_label: Label = $Center/LegalText
@onready var footer_label: Label = $Footer/LegalFooter


func _ready() -> void:
	print("[Boot] ready, applying theme and warning")
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_apply_logo()
	_apply_footer()
	_register_default_audio()
	_show_warning_if_needed()
	call_deferred("_go_to_main")


func _go_to_main() -> void:
	await get_tree().create_timer(delay_seconds).timeout
	var sm = _get_autoload("SceneManager")
	if sm:
		print("[Boot] transitioning to main_menu")
		sm.change_scene("main_menu")
	else:
		print("[Boot] SceneManager missing, cannot change scene")


func _show_warning_if_needed() -> void:
	var lm = _get_autoload("LegalManager")
	if lm == null:
		var cfg = _get_autoload("ConfigManager")
		if warning_label and cfg:
			var assets: Dictionary = cfg.get_template_assets_config()
			var warn: String = assets.get("legal", {}).get("epilepsy_warning", "")
			warning_label.text = warn
		return
	if not lm.is_epilepsy_warning_enabled():
		return
	if warning_label:
		warning_label.text = lm.get_epilepsy_warning_text()
	if legal_text_label and lm:
		legal_text_label.text = lm.get_credits_text()


func _apply_logo() -> void:
	var cfg = _get_autoload("ConfigManager")
	var logo_path := ""
	var fallback := "OneDayGames"
	if cfg:
		var assets: Dictionary = cfg.get_template_assets_config()
		logo_path = assets.get("company", {}).get("logo_path", "")
		fallback = assets.get("company", {}).get("fallback_text", fallback)
	var tex := _load_texture(logo_path)
	_set_logo(company_logo_tex, company_logo_fallback, tex, fallback)


func _apply_footer() -> void:
	var footer_text := "© OneDayGames. All rights reserved."
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		var assets: Dictionary = cfg.get_template_assets_config()
		footer_text = assets.get("legal", {}).get("footer", footer_text)
	if footer_label:
		footer_label.text = footer_text


func _register_default_audio() -> void:
	var audio = _get_autoload("AudioManager")
	if audio == null:
		return
	var cfg = _get_autoload("ConfigManager")
	if cfg:
		var registry: Dictionary = cfg.get_template_audio_registry()
		if audio.has_method("register_from_registry"):
			audio.register_from_registry(registry)
	if audio.has_method("register_sfx"):
		audio.register_sfx("ui_click", _build_click_sample())


func _build_click_sample() -> AudioStreamWAV:
	var sample: AudioStreamWAV = AudioStreamWAV.new()
	sample.format = AudioStreamWAV.FORMAT_8_BITS
	sample.mix_rate = 22050
	sample.stereo = false
	var data := PackedByteArray()
	for i in range(40):
		var value := 127 + 60 * sin(2.0 * PI * float(i) / 10.0)
		data.append(clamp(value, 0, 255))
	sample.data = data
	return sample


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
