## Autoload facade that wires pointer normalization and gesture recognition.
class_name GdGestureAutoload
extends Node

const PointerUnifierModule = preload("src/pointer_unifier_module.gd")
const GestureRecognizerModule = preload("src/gesture_recognizer_module.gd")

## Emitted when a pointer is pressed.
signal pointer_pressed(event)
## Emitted when a pointer drags.
signal pointer_dragged(event)
## Emitted when a pointer is released.
signal pointer_released(event)

## Emitted when any gesture is detected.
signal gesture_detected(gesture_type: String, data: Dictionary)
## Emitted for tap gestures.
signal tap_detected(position: Vector2, index: int)
## Emitted for double tap gestures.
signal double_tap_detected(position: Vector2)
## Emitted for long press gestures.
signal long_press_detected(position: Vector2)
## Emitted for swipe gestures.
signal swipe_detected(direction: Vector2, speed: float)
## Emitted when drag starts.
signal drag_started(position: Vector2, index: int)
## Emitted when drag updates.
signal drag_updated(position: Vector2, relative: Vector2, index: int)
## Emitted when drag ends.
signal drag_ended(position: Vector2, index: int)
## Emitted for pinch gestures.
signal pinch_detected(scale_delta: float)

var _pointer_unifier: PointerUnifierModule = PointerUnifierModule.new()
var _gesture_recognizer: GestureRecognizerModule = GestureRecognizerModule.new()

func _ready() -> void:
	setup()
	set_process_unhandled_input(true)

## Configures internal modules and rewires signal forwarding.
func setup(config: GestureRecognizerModule.GestureConfig = null) -> void:
	if _pointer_unifier.pointer_pressed.is_connected(_on_pointer_pressed):
		_pointer_unifier.pointer_pressed.disconnect(_on_pointer_pressed)
	if _pointer_unifier.pointer_dragged.is_connected(_on_pointer_dragged):
		_pointer_unifier.pointer_dragged.disconnect(_on_pointer_dragged)
	if _pointer_unifier.pointer_released.is_connected(_on_pointer_released):
		_pointer_unifier.pointer_released.disconnect(_on_pointer_released)
	if config == null:
		_gesture_recognizer.setup(self)
	else:
		_gesture_recognizer.setup(self, config)
	_pointer_unifier.pointer_pressed.connect(_on_pointer_pressed)
	_pointer_unifier.pointer_dragged.connect(_on_pointer_dragged)
	_pointer_unifier.pointer_released.connect(_on_pointer_released)
	_wire_gesture_signals()

func _unhandled_input(event: InputEvent) -> void:
	_pointer_unifier.process_input(event)

## Returns the touch count currently tracked by recognizer.
func get_touch_count() -> int:
	return _gesture_recognizer.get_touch_count()

## Returns the current gesture label.
func get_current_gesture() -> String:
	return _gesture_recognizer.get_current_gesture()

## Triggers haptic feedback using recognizer configuration.
func trigger_haptic(strength: float = -1.0) -> void:
	_gesture_recognizer.trigger_haptic(strength)

## Exposes the pointer unifier module for custom wiring.
func get_pointer_unifier_module() -> PointerUnifierModule:
	return _pointer_unifier

## Exposes the gesture recognizer module for custom wiring.
func get_gesture_recognizer_module() -> GestureRecognizerModule:
	return _gesture_recognizer

func _on_pointer_pressed(event: Object) -> void:
	_gesture_recognizer.process_pointer_event(event)
	pointer_pressed.emit(event)

func _on_pointer_dragged(event: Object) -> void:
	_gesture_recognizer.process_pointer_event(event)
	pointer_dragged.emit(event)

func _on_pointer_released(event: Object) -> void:
	_gesture_recognizer.process_pointer_event(event)
	pointer_released.emit(event)

func _wire_gesture_signals() -> void:
	if _gesture_recognizer.gesture_detected.is_connected(_forward_gesture_detected):
		return
	_gesture_recognizer.gesture_detected.connect(_forward_gesture_detected)
	_gesture_recognizer.tap_detected.connect(_forward_tap_detected)
	_gesture_recognizer.double_tap_detected.connect(_forward_double_tap_detected)
	_gesture_recognizer.long_press_detected.connect(_forward_long_press_detected)
	_gesture_recognizer.swipe_detected.connect(_forward_swipe_detected)
	_gesture_recognizer.drag_started.connect(_forward_drag_started)
	_gesture_recognizer.drag_updated.connect(_forward_drag_updated)
	_gesture_recognizer.drag_ended.connect(_forward_drag_ended)
	_gesture_recognizer.pinch_detected.connect(_forward_pinch_detected)

func _forward_gesture_detected(gesture_type: String, data: Dictionary) -> void:
	gesture_detected.emit(gesture_type, data)

func _forward_tap_detected(position: Vector2, index: int) -> void:
	tap_detected.emit(position, index)

func _forward_double_tap_detected(position: Vector2) -> void:
	double_tap_detected.emit(position)

func _forward_long_press_detected(position: Vector2) -> void:
	long_press_detected.emit(position)

func _forward_swipe_detected(direction: Vector2, speed: float) -> void:
	swipe_detected.emit(direction, speed)

func _forward_drag_started(position: Vector2, index: int) -> void:
	drag_started.emit(position, index)

func _forward_drag_updated(position: Vector2, relative: Vector2, index: int) -> void:
	drag_updated.emit(position, relative, index)

func _forward_drag_ended(position: Vector2, index: int) -> void:
	drag_ended.emit(position, index)

func _forward_pinch_detected(scale_delta: float) -> void:
	pinch_detected.emit(scale_delta)
