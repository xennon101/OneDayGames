extends Node

signal rebind_started(action_name)
signal rebind_finished(action_name, event)
signal rebind_cancelled(action_name)

var DEFAULT_ACTION_CONFIGS := {
	"move_left": [{"type": "key", "keycode": Key.KEY_A}],
	"move_right": [{"type": "key", "keycode": Key.KEY_D}],
	"move_up": [{"type": "key", "keycode": Key.KEY_W}],
	"move_down": [{"type": "key", "keycode": Key.KEY_S}],
	"action_primary": [{"type": "mouse_button", "button_index": MOUSE_BUTTON_LEFT}],
	"pause": [{"type": "key", "keycode": Key.KEY_ESCAPE}],
	"ui_accept": [{"type": "key", "keycode": Key.KEY_ENTER}],
	"ui_cancel": [{"type": "key", "keycode": Key.KEY_ESCAPE}]
}

var _listening_action: String = ""


func _ready() -> void:
	apply_bindings_from_config()


func apply_bindings_from_config() -> void:
	var config: Dictionary = _get_config_actions()
	for action in DEFAULT_ACTION_CONFIGS.keys():
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var events: Array = config.get(action, DEFAULT_ACTION_CONFIGS[action])
		for ev_cfg in events:
			var ev := _config_to_event(ev_cfg)
			if ev:
				InputMap.action_add_event(action, ev)


func start_rebind(action_name: String) -> void:
	if not InputMap.has_action(action_name):
		return
	_listening_action = action_name
	emit_signal("rebind_started", action_name)


func cancel_rebind() -> void:
	if _listening_action.is_empty():
		return
	var action := _listening_action
	_listening_action = ""
	emit_signal("rebind_cancelled", action)


func is_listening_for_rebind() -> bool:
	return not _listening_action.is_empty()


func _input(event: InputEvent) -> void:
	if _listening_action.is_empty():
		return
	if event is InputEventKey and event.keycode == Key.KEY_ESCAPE:
		cancel_rebind()
		return
	if event.is_pressed() and not event.is_echo():
		_set_binding(_listening_action, event)
		var action := _listening_action
		_listening_action = ""
		emit_signal("rebind_finished", action, event)


func _set_binding(action_name: String, event: InputEvent) -> void:
	InputMap.action_erase_events(action_name)
	InputMap.action_add_event(action_name, event)
	var actions: Dictionary = _get_config_actions()
	actions[action_name] = [_event_to_config(event)]
	if Engine.has_singleton("ConfigManager"):
		var cfg = Engine.get_singleton("ConfigManager")
		cfg.set_setting("input", "actions", actions)


func _get_config_actions() -> Dictionary:
	if Engine.has_singleton("ConfigManager"):
		var cfg = Engine.get_singleton("ConfigManager")
		var actions: Dictionary = cfg.get_setting("input", "actions", {})
		if typeof(actions) == TYPE_DICTIONARY:
			return actions
	return {}


func _config_to_event(data: Dictionary) -> InputEvent:
	var ev_type: String = data.get("type", "")
	match ev_type:
		"key":
			var ev := InputEventKey.new()
			ev.keycode = data.get("keycode", 0)
			return ev
		"mouse_button":
			var mev := InputEventMouseButton.new()
			mev.button_index = data.get("button_index", MOUSE_BUTTON_LEFT)
			return mev
		_:
			return null


func _event_to_config(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		return {"type": "key", "keycode": event.keycode}
	if event is InputEventMouseButton:
		return {"type": "mouse_button", "button_index": event.button_index}
	return {}


func get_default_actions() -> Dictionary:
	return DEFAULT_ACTION_CONFIGS.duplicate(true)
