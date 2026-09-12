extends SceneTree

const PointerUnifierModule = preload("res://addon/src/pointer_unifier_module.gd")

var _failures := 0
var _assertions := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_gui_accepted_is_ignored()
	_test_screen_cancel_and_removed_pointer_drag()
	_test_focus_style_cancel_all()
	_test_synthesized_mouse_is_ignored()
	if _failures == 0:
		print("PASS gd-gesture pointer_unifier_module_test assertions=", _assertions)
	quit(_failures)

func _test_gui_accepted_is_ignored() -> void:
	var module := PointerUnifierModule.new()
	var pressed := [0]
	module.pointer_pressed.connect(func(_event: Object) -> void: pressed[0] += 1)
	var touch := InputEventScreenTouch.new()
	touch.index = 3
	touch.pressed = true
	module.process_input(touch, true)
	_assert(pressed[0] == 0, "GUI-accepted events must not enter the pointer stream")

func _test_screen_cancel_and_removed_pointer_drag() -> void:
	var module := PointerUnifierModule.new()
	var canceled: Array = []
	var dragged := [0]
	module.pointer_canceled.connect(func(event: Object) -> void: canceled.append([event.index, event.cancel_reason]))
	module.pointer_dragged.connect(func(_event: Object) -> void: dragged[0] += 1)
	var touch := InputEventScreenTouch.new()
	touch.index = 2
	touch.position = Vector2(10, 20)
	touch.pressed = true
	module.process_input(touch)
	var cancel := InputEventScreenTouch.new()
	cancel.index = 2
	cancel.position = Vector2(12, 20)
	cancel.pressed = false
	cancel.canceled = true
	module.process_input(cancel)
	var removed_drag := InputEventScreenDrag.new()
	removed_drag.index = 2
	removed_drag.position = Vector2(30, 20)
	module.process_input(removed_drag)
	_assert(canceled == [[2, "pointer_canceled"]], "screen cancellation should retain pointer identity")
	_assert(dragged[0] == 0, "removed pointers cannot resume through later drag events")

func _test_focus_style_cancel_all() -> void:
	var module := PointerUnifierModule.new()
	var reasons: Array[String] = []
	module.pointer_canceled.connect(func(event: Object) -> void: reasons.append(event.cancel_reason))
	for index in [0, 1]:
		var touch := InputEventScreenTouch.new()
		touch.index = index
		touch.pressed = true
		module.process_input(touch)
	module.cancel_all("focus_lost")
	module.cancel_all("focus_lost")
	_assert(reasons == ["focus_lost", "focus_lost"], "focus loss cancels each pointer exactly once")

func _test_synthesized_mouse_is_ignored() -> void:
	var module := PointerUnifierModule.new()
	var presses := [0]
	module.pointer_pressed.connect(func(_event: Object) -> void: presses[0] += 1)
	var synthetic := InputEventMouseButton.new()
	synthetic.device = -1
	synthetic.button_index = MOUSE_BUTTON_LEFT
	synthetic.pressed = true
	module.process_input(synthetic)
	_assert(presses[0] == 0, "touch-synthesized mouse input must not duplicate a pointer")
	var mouse := InputEventMouseButton.new()
	mouse.device = 0
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	module.process_input(mouse)
	_assert(presses[0] == 1, "native mouse input remains supported")

func _assert(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		push_error("FAIL: " + message)
		_failures += 1
