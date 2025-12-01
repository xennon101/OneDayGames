extends Control

func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_populate()
	$Center/BackButton.pressed.connect(_on_back_pressed)


func _populate() -> void:
	if not Engine.has_singleton("LegalManager"):
		return
	var lm = Engine.get_singleton("LegalManager")
	$Center/Company.text = lm.get_company_name()
	$Center/Website.text = lm.get_website_url()
	$Center/CreditsText.text = lm.get_credits_text()
	$Center/Copy.text = lm.get_copyright()


func _on_back_pressed() -> void:
	if Engine.has_singleton("SceneManager"):
		Engine.get_singleton("SceneManager").return_to_main_menu()
