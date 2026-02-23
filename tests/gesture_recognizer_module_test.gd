extends SceneTree

const PointerUnifierModule = preload("res://src/pointer_unifier_module.gd")
const GestureRecognizerModule = preload("res://src/gesture_recognizer_module.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_touch_count_lifecycle()
	_test_drag_state_transitions()
	_test_pinch_state_assignment()
	quit()

func _test_touch_count_lifecycle() -> void:
	var owner: Node = Node.new()
	get_root().add_child(owner)
	var recognizer: GestureRecognizerModule = GestureRecognizerModule.new()
	recognizer.setup(owner)

	recognizer.process_pointer_event(_pointer_event("press", Vector2(10, 10), Vector2.ZERO, 0, true))
	_assert(recognizer.get_touch_count() == 1, "touch count should increase on press")

	recognizer.process_pointer_event(_pointer_event("release", Vector2(10, 10), Vector2.ZERO, 0, false))
	_assert(recognizer.get_touch_count() == 0, "touch count should reset on release")
	_assert(recognizer.get_current_gesture() == "", "gesture should reset when all touches release")

	owner.queue_free()

func _test_drag_state_transitions() -> void:
	var owner: Node = Node.new()
	get_root().add_child(owner)
	var recognizer: GestureRecognizerModule = GestureRecognizerModule.new()
	var config: GestureRecognizerModule.GestureConfig = GestureRecognizerModule.GestureConfig.new()
	config.drag_threshold = 5
	recognizer.setup(owner, config)

	recognizer.process_pointer_event(_pointer_event("press", Vector2(25, 25), Vector2.ZERO, 0, true))
	recognizer.process_pointer_event(_pointer_event("drag", Vector2(35, 25), Vector2(10, 0), 0, true))
	_assert(recognizer.get_current_gesture() == "drag", "gesture should become drag once threshold exceeded")
	recognizer.process_pointer_event(_pointer_event("release", Vector2(35, 25), Vector2.ZERO, 0, false))
	_assert(recognizer.get_current_gesture() == "", "gesture should clear after drag release")
	owner.queue_free()

func _test_pinch_state_assignment() -> void:
	var owner: Node = Node.new()
	get_root().add_child(owner)
	var recognizer: GestureRecognizerModule = GestureRecognizerModule.new()
	recognizer.setup(owner)

	recognizer.process_pointer_event(_pointer_event("press", Vector2(10, 10), Vector2.ZERO, 0, true))
	recognizer.process_pointer_event(_pointer_event("press", Vector2(60, 10), Vector2.ZERO, 1, true))
	_assert(recognizer.get_current_gesture() == "pinch", "second touch should set pinch state")
	recognizer.process_pointer_event(_pointer_event("release", Vector2(10, 10), Vector2.ZERO, 0, false))
	recognizer.process_pointer_event(_pointer_event("release", Vector2(60, 10), Vector2.ZERO, 1, false))
	_assert(recognizer.get_current_gesture() == "", "pinch state should clear after both releases")
	owner.queue_free()

func _pointer_event(event_type: String, position: Vector2, relative: Vector2, index: int, pressed: bool) -> PointerUnifierModule.PointerEvent:
	var event: PointerUnifierModule.PointerEvent = PointerUnifierModule.PointerEvent.new()
	event.event_type = event_type
	event.position = position
	event.relative = relative
	event.index = index
	event.device = "touch"
	event.pressed = pressed
	event.timestamp_ms = Time.get_ticks_msec()
	return event

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
