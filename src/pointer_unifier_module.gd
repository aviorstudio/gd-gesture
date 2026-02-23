## Normalizes mouse and touch input events into a single pointer event stream.
class_name PointerUnifierModule
extends RefCounted

## Unified pointer event DTO emitted by PointerUnifierModule.
class PointerEvent extends RefCounted:
	## Pointer position in viewport space.
	var position: Vector2 = Vector2.ZERO
	## Relative movement since previous event.
	var relative: Vector2 = Vector2.ZERO
	## Pointer index (touch index or 0 for mouse).
	var index: int = 0
	## Input device type: "touch" or "mouse".
	var device: String = "touch"
	## Pressed state for the pointer.
	var pressed: bool = false
	## Pointer event type: "press", "release", or "drag".
	var event_type: String = "press"
	## Event timestamp in milliseconds.
	var timestamp_ms: int = 0

## Emitted when a pointer is pressed.
signal pointer_pressed(event: PointerEvent)
## Emitted when a pointer is moved while pressed.
signal pointer_dragged(event: PointerEvent)
## Emitted when a pointer is released.
signal pointer_released(event: PointerEvent)

## Processes an input event and emits normalized pointer events.
func process_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
		return
	if event is InputEventScreenDrag:
		_handle_screen_drag(event)
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_handle_mouse_motion(event)

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	var pointer_event: PointerEvent = _build_pointer_event(
		event.position,
		Vector2.ZERO,
		event.index,
		event.pressed,
		"touch",
		"press" if event.pressed else "release"
	)
	if event.pressed:
		pointer_pressed.emit(pointer_event)
		return
	pointer_released.emit(pointer_event)

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	var pointer_event: PointerEvent = _build_pointer_event(
		event.position,
		event.relative,
		event.index,
		true,
		"touch",
		"drag"
	)
	pointer_dragged.emit(pointer_event)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	var pointer_event: PointerEvent = _build_pointer_event(
		event.position,
		Vector2.ZERO,
		0,
		event.pressed,
		"mouse",
		"press" if event.pressed else "release"
	)
	if event.pressed:
		pointer_pressed.emit(pointer_event)
		return
	pointer_released.emit(pointer_event)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	var pointer_event: PointerEvent = _build_pointer_event(
		event.position,
		event.relative,
		0,
		true,
		"mouse",
		"drag"
	)
	pointer_dragged.emit(pointer_event)

func _build_pointer_event(position: Vector2, relative: Vector2, index: int, pressed: bool, device: String, event_type: String) -> PointerEvent:
	var pointer_event: PointerEvent = PointerEvent.new()
	pointer_event.position = position
	pointer_event.relative = relative
	pointer_event.index = index
	pointer_event.device = device
	pointer_event.pressed = pressed
	pointer_event.event_type = event_type
	pointer_event.timestamp_ms = Time.get_ticks_msec()
	return pointer_event
