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
	$Center/Company.text = LegalManager.get_company_name()
	$Center/Website.text = LegalManager.get_website_url()
	$Center/CreditsText.text = LegalManager.get_credits_text()
	$Center/Copy.text = LegalManager.get_copyright()


func _on_back_pressed() -> void:
	if Engine.has_singleton("SceneManager"):
		SceneManager.return_to_main_menu()
