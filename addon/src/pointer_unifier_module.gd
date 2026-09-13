## Normalizes mouse and touch input events into one owned pointer stream.
class_name PointerUnifierModule
extends RefCounted

## Unified pointer event DTO emitted by PointerUnifierModule.
class PointerEvent extends RefCounted:
	var position: Vector2 = Vector2.ZERO
	var relative: Vector2 = Vector2.ZERO
	var index: int = 0
	var device: String = "touch"
	var pressed: bool = false
	## "press", "release", "drag", or "cancel".
	var event_type: String = "press"
	var timestamp_ms: int = 0
	var cancel_reason: String = ""

signal pointer_pressed(event)
signal pointer_dragged(event)
signal pointer_released(event)
signal pointer_canceled(event)

var mouse_button: MouseButton = MOUSE_BUTTON_LEFT
var _active_touch_indices: Dictionary[int, bool] = {}
var _mouse_pressed: bool = false
var _last_positions: Dictionary[String, Vector2] = {}

## Processes input unless the caller reports that GUI already accepted it.
## Native mouse events synthesized from touch (device -1) are ignored so a
## physical contact cannot produce two pointer streams.
func process_input(event: InputEvent, gui_accepted: bool = false) -> void:
	if event == null or gui_accepted:
		return
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
		return
	if event is InputEventScreenDrag:
		_handle_screen_drag(event)
		return
	if event is InputEventMouseButton:
		if event.device == -1 or not _active_touch_indices.is_empty():
			return
		_handle_mouse_button(event)
		return
	if event is InputEventMouseMotion and _mouse_pressed:
		if event.device == -1 or not _active_touch_indices.is_empty():
			return
		_handle_mouse_motion(event)

## Cancels every currently owned pointer, for example on focus loss/teardown.
func cancel_all(reason: String = "canceled") -> void:
	for index in _active_touch_indices.keys():
		_emit_cancel(int(index), "touch", reason)
	_active_touch_indices.clear()
	if _mouse_pressed:
		_emit_cancel(0, "mouse", reason)
	_mouse_pressed = false
	_last_positions.clear()

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.canceled:
		if _active_touch_indices.has(event.index):
			_emit_cancel(event.index, "touch", "pointer_canceled", event.position)
		_active_touch_indices.erase(event.index)
		_last_positions.erase(_pointer_key("touch", event.index))
		return
	var event_type: String = "press" if event.pressed else "release"
	if event.pressed and _mouse_pressed:
		_emit_cancel(0, "mouse", "superseded_by_touch")
		_mouse_pressed = false
		_last_positions.erase(_pointer_key("mouse", 0))
	var pointer_event := _build_pointer_event(event.position, Vector2.ZERO, event.index, event.pressed, "touch", event_type)
	if event.pressed:
		_active_touch_indices[event.index] = true
		_last_positions[_pointer_key("touch", event.index)] = event.position
		pointer_pressed.emit(pointer_event)
	else:
		_active_touch_indices.erase(event.index)
		_last_positions.erase(_pointer_key("touch", event.index))
		pointer_released.emit(pointer_event)

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if not _active_touch_indices.has(event.index):
		return
	_last_positions[_pointer_key("touch", event.index)] = event.position
	pointer_dragged.emit(_build_pointer_event(event.position, event.relative, event.index, true, "touch", "drag"))

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != mouse_button:
		return
	_mouse_pressed = event.pressed
	var event_type: String = "press" if event.pressed else "release"
	var pointer_event := _build_pointer_event(event.position, Vector2.ZERO, 0, event.pressed, "mouse", event_type)
	if event.pressed:
		_last_positions[_pointer_key("mouse", 0)] = event.position
		pointer_pressed.emit(pointer_event)
	else:
		_last_positions.erase(_pointer_key("mouse", 0))
		pointer_released.emit(pointer_event)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	_last_positions[_pointer_key("mouse", 0)] = event.position
	pointer_dragged.emit(_build_pointer_event(event.position, event.relative, 0, true, "mouse", "drag"))

func _emit_cancel(index: int, device: String, reason: String, position: Vector2 = Vector2.INF) -> void:
	var key := _pointer_key(device, index)
	var resolved_position: Vector2 = _last_positions.get(key, Vector2.ZERO) if position == Vector2.INF else position
	var pointer_event := _build_pointer_event(resolved_position, Vector2.ZERO, index, false, device, "cancel")
	pointer_event.cancel_reason = reason
	pointer_canceled.emit(pointer_event)

func _pointer_key(device: String, index: int) -> String:
	return "%s:%d" % [device, index]

func _build_pointer_event(position: Vector2, relative: Vector2, index: int, pressed: bool, device: String, event_type: String) -> PointerEvent:
	var pointer_event := PointerEvent.new()
	pointer_event.position = position
	pointer_event.relative = relative
	pointer_event.index = index
	pointer_event.device = device
	pointer_event.pressed = pressed
	pointer_event.event_type = event_type
	pointer_event.timestamp_ms = Time.get_ticks_msec()
	return pointer_event
