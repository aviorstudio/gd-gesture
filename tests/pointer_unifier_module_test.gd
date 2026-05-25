extends SceneTree

const PointerUnifierModule = preload("res://addon/src/pointer_unifier_module.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_build_pointer_event_defaults()
	_test_build_pointer_event_drag_payload()
	quit()

func _test_build_pointer_event_defaults() -> void:
	var module: PointerUnifierModule = PointerUnifierModule.new()
	var pointer_event: PointerUnifierModule.PointerEvent = module._build_pointer_event(
		Vector2(32, 64),
		Vector2.ZERO,
		2,
		true,
		"touch",
		"press"
	)

	_assert(pointer_event.position == Vector2(32, 64), "position should be preserved")
	_assert(pointer_event.relative == Vector2.ZERO, "relative should be zero for press")
	_assert(pointer_event.index == 2, "index should be preserved")
	_assert(pointer_event.device == "touch", "device should match")
	_assert(pointer_event.pressed, "pressed should be true")
	_assert(pointer_event.event_type == "press", "event_type should match")
	_assert(pointer_event.timestamp_ms > 0, "timestamp_ms should be populated")

func _test_build_pointer_event_drag_payload() -> void:
	var module: PointerUnifierModule = PointerUnifierModule.new()
	var pointer_event: PointerUnifierModule.PointerEvent = module._build_pointer_event(
		Vector2(120, 90),
		Vector2(10, -4),
		1,
		true,
		"mouse",
		"drag"
	)

	_assert(pointer_event.relative == Vector2(10, -4), "drag relative movement should be preserved")
	_assert(pointer_event.device == "mouse", "device should be mouse")
	_assert(pointer_event.event_type == "drag", "event_type should be drag")

func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	quit(1)
