extends Node

## Lightweight publish/subscribe event bus for cross-system communication.
var _subscribers: Dictionary = {}


func subscribe(event_name: String, target: Object, method: String) -> void:
	if event_name.is_empty() or target == null or method.is_empty():
		return
	var listeners: Array = _subscribers.get(event_name, [])
	for entry in listeners:
		var target_ref: WeakRef = entry.get("target")
		var existing: Object = target_ref.get_ref()
		if existing == target and entry.get("method", "") == method:
			return
	listeners.append({"target": weakref(target), "method": method})
	_subscribers[event_name] = listeners


func unsubscribe(event_name: String, target: Object, method: String) -> void:
	var listeners: Array = _subscribers.get(event_name, [])
	var remaining: Array = []
	for entry in listeners:
		var target_ref: WeakRef = entry.get("target")
		var existing: Object = target_ref.get_ref()
		if existing == null:
			continue
		if existing == target and entry.get("method", "") == method:
			continue
		remaining.append(entry)
	if remaining.is_empty():
		_subscribers.erase(event_name)
	else:
		_subscribers[event_name] = remaining


func emit(event_name: String, payload: Variant = null) -> void:
	var listeners: Array = _subscribers.get(event_name, [])
	var remaining: Array = []
	for entry in listeners:
		var target_ref: WeakRef = entry.get("target")
		var target: Object = target_ref.get_ref()
		var method: String = entry.get("method", "")
		if target == null or not target.has_method(method):
			continue
		target.call(method, payload)
		remaining.append(entry)
	if remaining.is_empty():
		_subscribers.erase(event_name)
	else:
		_subscribers[event_name] = remaining
