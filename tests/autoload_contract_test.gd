extends SceneTree

const Autoload = preload("res://addon/autoload.gd")

var _failures := 0
var _assertions := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var facade: Node = Autoload.new()
	get_root().add_child(facade)
	var cancellations: Array = []
	facade.gesture_canceled.connect(func(index: int, reason: String) -> void: cancellations.append([index, reason]))
	var touch := InputEventScreenTouch.new()
	touch.index = 7
	touch.pressed = true
	facade.get_pointer_unifier_module().process_input(touch)
	facade._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	_assert(facade.get_touch_count() == 0, "focus loss clears recognizer ownership")
	_assert(cancellations == [[7, "focus_lost"]], "focus loss emits cancellation through facade")
	facade.queue_free()
	await process_frame
	if _failures == 0:
		print("PASS gd-gesture autoload_contract_test assertions=", _assertions)
	quit(_failures)

func _assert(condition: bool, message: String) -> void:
	_assertions += 1
	if not condition:
		push_error("FAIL: " + message)
		_failures += 1
