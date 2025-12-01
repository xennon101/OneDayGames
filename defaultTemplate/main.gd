extends Node

# Entry point that hands off to the boot scene via SceneManager.
func _ready() -> void:
	if Engine.has_singleton("SceneManager"):
		var sm = Engine.get_singleton("SceneManager")
		sm.change_scene("boot", false)
