extends Control

func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_populate()
	$Center/BackButton.pressed.connect(_on_back_pressed)


func _populate() -> void:
	var lm = _get_autoload("LegalManager")
	if lm == null:
		return
	$Center/Company.text = lm.get_company_name()
	$Center/Website.text = lm.get_website_url()
	$Center/CreditsText.text = lm.get_credits_text()
	$Center/Copy.text = lm.get_copyright()


func _on_back_pressed() -> void:
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.return_to_main_menu()


func _get_autoload(name: String) -> Object:
	var root := get_tree().get_root()
	if root.has_node(name):
		return root.get_node(name)
	if Engine.has_singleton(name):
		return Engine.get_singleton(name)
	return null
