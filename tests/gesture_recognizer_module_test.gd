extends SceneTree

const PointerUnifierModule = preload("res://addon/src/pointer_unifier_module.gd")
const GestureRecognizerModule = preload("res://addon/src/gesture_recognizer_module.gd")

var _failures := 0
var _assertions := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_per_pointer_concurrent_drags()
	_test_pinch_uses_moved_point_and_absolute_start_scale()
	_test_first_tap_and_double_tap_boundaries()
	_test_cancel_has_no_completion_gestures()
	await _test_canceled_long_press_stays_canceled()
	if _failures == 0:
		print("PASS gd-gesture gesture_recognizer_module_test assertions=", _assertions)
	quit(_failures)

func _recognizer(config: GestureRecognizerModule.GestureConfig = null) -> GestureRecognizerModule:
	var owner := Node.new()
	get_root().add_child(owner)
	var recognizer := GestureRecognizerModule.new()
	recognizer.setup(owner, config)
	return recognizer

func _test_per_pointer_concurrent_drags() -> void:
	var config := GestureRecognizerModule.GestureConfig.new()
	config.drag_threshold = 5
	var recognizer := _recognizer(config)
	var started: Array[int] = []
	var ended: Array[int] = []
	recognizer.drag_started.connect(func(_position: Vector2, index: int) -> void: started.append(index))
	recognizer.drag_ended.connect(func(_position: Vector2, index: int) -> void: ended.append(index))
	recognizer.process_pointer_event(_event("press", Vector2.ZERO, 0, 10))
	recognizer.process_pointer_event(_event("press", Vector2(100, 0), 1, 10))
	recognizer.process_pointer_event(_event("drag", Vector2(10, 0), 0, 20, Vector2(10, 0)))
	recognizer.process_pointer_event(_event("drag", Vector2(110, 0), 1, 20, Vector2(10, 0)))
	_assert(started == [0, 1], "each pointer should own its drag start")
	recognizer.process_pointer_event(_event("release", Vector2(10, 0), 0, 30))
	_assert(recognizer.get_current_gesture() == "drag", "releasing one drag must not clear the other")
	recognizer.process_pointer_event(_event("release", Vector2(110, 0), 1, 30))
	_assert(ended == [0, 1], "each pointer should own its drag end")
	_assert(recognizer.get_current_gesture().is_empty(), "gesture state clears after both releases")

func _test_pinch_uses_moved_point_and_absolute_start_scale() -> void:
	var recognizer := _recognizer()
	var scales: Array[float] = []
	var taps := [0]
	recognizer.pinch_detected.connect(func(scale: float) -> void: scales.append(scale))
	recognizer.tap_detected.connect(func(_position: Vector2, _index: int) -> void: taps[0] += 1)
	recognizer.process_pointer_event(_event("press", Vector2.ZERO, 0, 100))
	recognizer.process_pointer_event(_event("press", Vector2(10, 0), 1, 100))
	recognizer.process_pointer_event(_event("drag", Vector2(20, 0), 1, 110, Vector2(10, 0)))
	recognizer.process_pointer_event(_event("drag", Vector2(-10, 0), 0, 120, Vector2(-10, 0)))
	_assert(scales.size() == 2, "each pinch move should emit")
	_assert(is_equal_approx(scales[0], 2.0), "first pinch must include the moved point")
	_assert(is_equal_approx(scales[1], 3.0), "pinch scale is absolute from pinch start")
	recognizer.process_pointer_event(_event("release", Vector2(-10, 0), 0, 130))
	recognizer.process_pointer_event(_event("release", Vector2(20, 0), 1, 130))
	_assert(taps[0] == 0, "pointers participating in a pinch do not also tap")

func _test_first_tap_and_double_tap_boundaries() -> void:
	var config := GestureRecognizerModule.GestureConfig.new()
	config.drag_threshold = 10
	config.double_tap_max_delay = 0.3
	var recognizer := _recognizer(config)
	var taps := [0]
	var doubles := [0]
	recognizer.tap_detected.connect(func(_position: Vector2, _index: int) -> void: taps[0] += 1)
	recognizer.double_tap_detected.connect(func(_position: Vector2) -> void: doubles[0] += 1)
	_tap(recognizer, Vector2.ZERO, 0, 1)
	_assert(taps[0] == 1 and doubles[0] == 0, "first startup tap must not double tap")
	_tap(recognizer, Vector2(30, 0), 0, 100)
	_assert(doubles[0] == 0, "near-time distant taps must not double tap")
	_tap(recognizer, Vector2(30, 0), 0, 500)
	_assert(doubles[0] == 0, "late taps must not double tap")
	_tap(recognizer, Vector2(31, 0), 0, 700)
	_assert(doubles[0] == 1, "nearby timely taps should double tap")

func _test_cancel_has_no_completion_gestures() -> void:
	var recognizer := _recognizer()
	var taps := [0]
	var swipes := [0]
	var canceled: Array = []
	recognizer.tap_detected.connect(func(_position: Vector2, _index: int) -> void: taps[0] += 1)
	recognizer.swipe_detected.connect(func(_direction: Vector2, _speed: float) -> void: swipes[0] += 1)
	recognizer.gesture_canceled.connect(func(index: int, reason: String) -> void: canceled.append([index, reason]))
	recognizer.process_pointer_event(_event("press", Vector2.ZERO, 2, 100))
	var cancel := _event("cancel", Vector2(100, 0), 2, 110)
	cancel.cancel_reason = "focus_lost"
	recognizer.process_pointer_event(cancel)
	recognizer.process_pointer_event(_event("release", Vector2(100, 0), 2, 120))
	_assert(canceled == [[2, "focus_lost"]], "cancel should identify pointer and reason")
	_assert(taps[0] == 0 and swipes[0] == 0, "canceled pointers cannot tap or swipe later")
	_assert(recognizer.get_touch_count() == 0, "cancel removes pointer ownership")

func _test_canceled_long_press_stays_canceled() -> void:
	var config := GestureRecognizerModule.GestureConfig.new()
	config.long_press_duration = 0.01
	var recognizer := _recognizer(config)
	var long_presses := [0]
	recognizer.long_press_detected.connect(func(_position: Vector2) -> void: long_presses[0] += 1)
	recognizer.process_pointer_event(_event("press", Vector2.ZERO, 4, 100))
	var cancel := _event("cancel", Vector2.ZERO, 4, 101)
	cancel.cancel_reason = "pointer_canceled"
	recognizer.process_pointer_event(cancel)
	await create_timer(0.03).timeout
	_assert(long_presses[0] == 0, "canceled pointer cannot emit delayed long press")

func _tap(recognizer: GestureRecognizerModule, position: Vector2, index: int, timestamp_ms: int) -> void:
	recognizer.process_pointer_event(_event("press", position, index, timestamp_ms))
	recognizer.process_pointer_event(_event("release", position, index, timestamp_ms + 10))

func _event(event_type: String, position: Vector2, index: int, timestamp_ms: int, relative: Vector2 = Vector2.ZERO, device: String = "touch") -> PointerUnifierModule.PointerEvent:
	var event := PointerUnifierModule.PointerEvent.new()
	event.event_type = event_type
	event.position = position
	event.relative = relative
	event.index = index
	event.device = device
	event.pressed = event_type in ["press", "drag"]
	event.timestamp_ms = timestamp_ms
	return event

func _assert(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		push_error("FAIL: " + message)
		_failures += 1
