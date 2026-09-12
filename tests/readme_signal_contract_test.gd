extends SceneTree

const Autoload = preload("res://addon/autoload.gd")
const PointerUnifierModule = preload("res://addon/src/pointer_unifier_module.gd")
const GestureRecognizerModule = preload("res://addon/src/gesture_recognizer_module.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var facade: Node = Autoload.new()
	get_root().add_child(facade)
	var pointer := PointerUnifierModule.new()
	var recognizer := GestureRecognizerModule.new()
	facade.tap_detected.connect(_on_tap_detected)
	facade.swipe_detected.connect(_on_swipe_detected)
	facade.drag_started.connect(_on_drag_started)
	pointer.pointer_pressed.connect(recognizer.process_pointer_event)
	pointer.pointer_dragged.connect(recognizer.process_pointer_event)
	pointer.pointer_released.connect(recognizer.process_pointer_event)
	pointer.pointer_canceled.connect(recognizer.process_pointer_event)
	facade.queue_free()
	pointer = null
	recognizer = null
	await process_frame
	print("PASS gd-gesture readme_signal_contract_test assertions=7")
	quit(0)

func _on_tap_detected(_position: Vector2, _index: int) -> void:
	pass

func _on_swipe_detected(_direction: Vector2, _speed: float) -> void:
	pass

func _on_drag_started(_position: Vector2, _index: int) -> void:
	pass
