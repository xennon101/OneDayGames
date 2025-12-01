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
	if Engine.has_singleton("SaveManager"):
		can_load = SaveManager.game_supports_saves and SaveManager.has_save()
	load_button.disabled = not can_load


func _on_start_pressed() -> void:
	if Engine.has_singleton("SceneManager"):
		SceneManager.change_scene("gameplay")


func _on_load_pressed() -> void:
	if load_button.disabled:
		return
	if Engine.has_singleton("SaveManager"):
		var data := SaveManager.load_game()
		# Real games should consume data; placeholder just enters gameplay.
		if Engine.has_singleton("SceneManager"):
			SceneManager.change_scene("gameplay")


func _on_settings_pressed() -> void:
	if Engine.has_singleton("SceneManager"):
		SceneManager.change_scene("settings")


func _on_credits_pressed() -> void:
	if Engine.has_singleton("SceneManager"):
		SceneManager.change_scene("credits")


func _on_exit_pressed() -> void:
	if Engine.has_singleton("EventBus"):
		EventBus.emit("request_quit_game")
	elif Engine.has_singleton("SceneManager"):
		SceneManager.quit()
