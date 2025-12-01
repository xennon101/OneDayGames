extends Control

@export var delay_seconds := 1.0

func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_show_warning_if_needed()
	_call_deferred("_go_to_main")


func _go_to_main() -> void:
	await get_tree().create_timer(delay_seconds).timeout
	if Engine.has_singleton("SceneManager"):
		SceneManager.change_scene("main_menu")


func _show_warning_if_needed() -> void:
	if not Engine.has_singleton("LegalManager"):
		return
	if not LegalManager.is_epilepsy_warning_enabled():
		return
	var warning_label := $Warning
	if warning_label:
		warning_label.text = LegalManager.get_epilepsy_warning_text()
