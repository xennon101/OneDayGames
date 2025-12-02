extends Control

func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	$Center/ExitButton.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
	_play_ui_click()
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.return_to_main_menu()


func _play_ui_click() -> void:
	var audio = _get_autoload("AudioManager")
	if audio and audio.has_method("play_sfx"):
		audio.play_sfx("ui_click")


func _get_autoload(name: String) -> Object:
	var root := get_tree().get_root()
	if root.has_node(name):
		return root.get_node(name)
	if Engine.has_singleton(name):
		return Engine.get_singleton(name)
	return null
