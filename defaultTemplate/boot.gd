extends Control

@export var delay_seconds := 1.0

func _ready() -> void:
	print("[Boot] ready, applying theme and warning")
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_show_warning_if_needed()
	call_deferred("_go_to_main")


func _go_to_main() -> void:
	await get_tree().create_timer(delay_seconds).timeout
	if Engine.has_singleton("SceneManager"):
		var sm = Engine.get_singleton("SceneManager")
		print("[Boot] transitioning to main_menu")
		sm.change_scene("main_menu")
	else:
		print("[Boot] SceneManager missing, cannot change scene")


func _show_warning_if_needed() -> void:
	if not Engine.has_singleton("LegalManager"):
		return
	var lm = Engine.get_singleton("LegalManager")
	if not lm.is_epilepsy_warning_enabled():
		return
	var warning_label := $Warning
	if warning_label:
		warning_label.text = lm.get_epilepsy_warning_text()
