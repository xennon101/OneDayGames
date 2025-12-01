extends Control

func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	$Center/ExitButton.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
	if Engine.has_singleton("SceneManager"):
		Engine.get_singleton("SceneManager").return_to_main_menu()
