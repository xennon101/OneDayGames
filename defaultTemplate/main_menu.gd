extends Control

@onready var start_button: Button = $Center/Menu/StartButton
@onready var load_button: Button = $Center/Menu/LoadButton
@onready var settings_button: Button = $Center/Menu/SettingsButton
@onready var credits_button: Button = $Center/Menu/CreditsButton
@onready var exit_button: Button = $Center/Menu/ExitButton


func _ready() -> void:
	var theme_res := load("res://shared/ui/default_theme.tres")
	if theme_res:
		theme = theme_res
	_refresh_load_button()
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _refresh_load_button() -> void:
	var can_load := false
	var save_manager = _get_autoload("SaveManager")
	if save_manager:
		can_load = save_manager.game_supports_saves and save_manager.has_save()
	load_button.disabled = not can_load


func _on_start_pressed() -> void:
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.change_scene("gameplay")


func _on_load_pressed() -> void:
	if load_button.disabled:
		return
	var save_manager = _get_autoload("SaveManager")
	if save_manager:
		var data: Dictionary = save_manager.load_game()
		# Real games should consume data; placeholder just enters gameplay.
		var sm = _get_autoload("SceneManager")
		if sm:
			sm.change_scene("gameplay")


func _on_settings_pressed() -> void:
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.change_scene("settings")


func _on_credits_pressed() -> void:
	var sm = _get_autoload("SceneManager")
	if sm:
		sm.change_scene("credits")


func _on_exit_pressed() -> void:
	var bus = _get_autoload("EventBus")
	if bus:
		bus.emit("request_quit_game")
	else:
		var sm = _get_autoload("SceneManager")
		if sm:
			sm.quit()


func _get_autoload(name: String) -> Object:
	var root := get_tree().get_root()
	if root.has_node(name):
		return root.get_node(name)
	if Engine.has_singleton(name):
		return Engine.get_singleton(name)
	return null
