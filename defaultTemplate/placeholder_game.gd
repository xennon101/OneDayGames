extends Control

func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	$Center/ExitButton.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
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
