extends Node

var current_scene_id: String = ""
var _loading: bool = false
var _loading_screen: Node = null
var use_fade: bool = false
var scene_config: Object = null
var mute_warnings: bool = false


func _ready() -> void:
	if Engine.has_singleton("SceneConfig"):
		scene_config = Engine.get_singleton("SceneConfig")
	if Engine.has_singleton("EventBus"):
		var bus = Engine.get_singleton("EventBus")
		bus.subscribe("request_quit_game", self, "_on_request_quit_game")
		bus.subscribe("request_return_to_main_menu", self, "_on_request_return_to_main_menu")


func change_scene(id: String, show_loading := true) -> void:
	if _loading:
		return
	if scene_config == null and Engine.has_singleton("SceneConfig"):
		scene_config = Engine.get_singleton("SceneConfig")
	if scene_config == null:
		if not mute_warnings:
			push_warning("SceneManager: SceneConfig missing")
		return
	if not scene_config.has(id):
		if not mute_warnings:
			push_warning("SceneManager: unknown scene id %s" % id)
		return
	_loading = true
	await _perform_scene_change(id, show_loading)
	_loading = false


func reload_current_scene(show_loading := true) -> void:
	if current_scene_id.is_empty():
		return
	await change_scene(current_scene_id, show_loading)


func return_to_main_menu(show_loading := true) -> void:
	await change_scene("main_menu", show_loading)


func get_current_scene_id() -> String:
	return current_scene_id


func quit() -> void:
	get_tree().quit()


func _perform_scene_change(id: String, show_loading: bool) -> void:
	if show_loading:
		_show_loading_screen()
	if scene_config == null and Engine.has_singleton("SceneConfig"):
		scene_config = Engine.get_singleton("SceneConfig")
	var path: String = scene_config.get_scene_path(id)
	var packed := await _load_scene_async(path)
	if packed == null:
		push_warning("SceneManager: failed to load scene at %s" % path)
		_hide_loading_screen()
		return
	if use_fade:
		await _fade_out()
	get_tree().change_scene_to_packed(packed)
	current_scene_id = id
	if use_fade:
		await _fade_in()
	_hide_loading_screen()


func _load_scene_async(path: String) -> PackedScene:
	var status := ResourceLoader.load_threaded_request(path)
	if status != OK:
		return null
	while true:
		var poll := ResourceLoader.load_threaded_get_status(path)
		if poll == ResourceLoader.THREAD_LOAD_LOADED:
			var res := ResourceLoader.load_threaded_get(path)
			return res if res is PackedScene else null
		if poll == ResourceLoader.THREAD_LOAD_FAILED:
			return null
		await get_tree().process_frame
	return null


func _show_loading_screen() -> void:
	if scene_config == null and Engine.has_singleton("SceneConfig"):
		scene_config = Engine.get_singleton("SceneConfig")
	if scene_config == null or not scene_config.has("loading"):
		return
	var loading_path: String = scene_config.get_scene_path("loading")
	var packed := ResourceLoader.load(loading_path)
	if packed is PackedScene:
		_loading_screen = packed.instantiate()
		get_tree().root.add_child(_loading_screen)


func _hide_loading_screen() -> void:
	if _loading_screen:
		_loading_screen.queue_free()
		_loading_screen = null


func _fade_out() -> void:
	var layer := _get_fade_layer()
	if layer == null:
		return
	layer.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(layer, "modulate:a", 1.0, 0.3)
	await tween.finished


func _fade_in() -> void:
	var layer := _get_fade_layer()
	if layer == null:
		return
	var tween := create_tween()
	tween.tween_property(layer, "modulate:a", 0.0, 0.3)
	await tween.finished


func _get_fade_layer() -> ColorRect:
	var existing := get_node_or_null("FadeLayer")
	if existing:
		return existing
	var rect := ColorRect.new()
	rect.name = "FadeLayer"
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(rect)
	return rect


func _on_request_quit_game(_payload: Variant = null) -> void:
	quit()


func _on_request_return_to_main_menu(_payload: Variant = null) -> void:
	return_to_main_menu()
