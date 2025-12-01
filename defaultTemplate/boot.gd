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
	var sm = _get_autoload("SceneManager")
	if sm:
		print("[Boot] transitioning to main_menu")
		sm.change_scene("main_menu")
	else:
		print("[Boot] SceneManager missing, cannot change scene")


func _show_warning_if_needed() -> void:
	var lm = _get_autoload("LegalManager")
	if lm == null:
		return
	if not lm.is_epilepsy_warning_enabled():
		return
	var warning_label := $Warning
	if warning_label:
		warning_label.text = lm.get_epilepsy_warning_text()


func _get_autoload(name: String) -> Object:
	var root := get_tree().get_root()
	if root.has_node(name):
		return root.get_node(name)
	if Engine.has_singleton(name):
		return Engine.get_singleton(name)
	return null
