## Detects high-level gestures from normalized pointer events.
class_name GestureRecognizerModule
extends RefCounted

const PointerUnifierModule = preload("pointer_unifier_module.gd")

## Runtime configuration for gesture detection.
class GestureConfig extends RefCounted:
	## Max duration for a tap in seconds.
	var tap_max_duration: float = 0.2
	## Hold duration before long press in seconds.
	var long_press_duration: float = 0.5
	## Minimum movement before drag is recognized.
	var drag_threshold: int = 10
	## Minimum swipe distance in pixels.
	var swipe_min_distance: int = 50
	## Maximum swipe duration in seconds.
	var swipe_max_time: float = 0.3
	## Max delay between taps to detect a double tap.
	var double_tap_max_delay: float = 0.3
	## Enable mobile haptic feedback.
	var haptic_enabled: bool = true
	## Default haptic intensity [0, 1].
	var haptic_intensity: float = 0.3
	## Distance threshold where long-press is canceled while moving.
	var long_press_drag_threshold: int = 30

## Generic signal for all recognized gesture events.
signal gesture_detected(gesture_type: String, data: Dictionary)
## Emitted when a tap is detected.
signal tap_detected(position: Vector2, index: int)
## Emitted when a double tap is detected.
signal double_tap_detected(position: Vector2)
## Emitted when a long press is detected.
signal long_press_detected(position: Vector2)
## Emitted when a swipe is detected.
signal swipe_detected(direction: Vector2, speed: float)
## Emitted when a drag starts.
signal drag_started(position: Vector2, index: int)
## Emitted while drag moves.
signal drag_updated(position: Vector2, relative: Vector2, index: int)
## Emitted when drag ends.
signal drag_ended(position: Vector2, index: int)
## Emitted when pinch scale changes.
signal pinch_detected(scale_delta: float)

var _owner: Node = null
var _config: GestureConfig = GestureConfig.new()
var _touch_points: Dictionary[int, Vector2] = {}
var _gesture_start_time: Dictionary[int, float] = {}
var _touch_start_positions: Dictionary[int, Vector2] = {}
var _current_gesture: String = ""
var _is_dragging: bool = false
var _long_press_timer: Timer = null
var _last_tap_time: float = 0.0
var _last_tap_position: Vector2 = Vector2.ZERO
var _pending_long_press_index: int = -1

## Initializes the recognizer and attaches internal timer to owner.
func setup(owner: Node, config: GestureConfig = null) -> void:
	_owner = owner
	if config != null:
		_config = config
	if _long_press_timer != null and is_instance_valid(_long_press_timer):
		_long_press_timer.queue_free()
	_long_press_timer = Timer.new()
	_long_press_timer.one_shot = true
	_long_press_timer.timeout.connect(_on_long_press_timeout)
	_owner.add_child(_long_press_timer)

## Processes a normalized pointer event.
func process_pointer_event(event: Object) -> void:
	if event == null:
		return
	if event.event_type == "press":
		_on_pointer_pressed(event)
		return
	if event.event_type == "drag":
		_on_pointer_dragged(event)
		return
	if event.event_type == "release":
		_on_pointer_released(event)

## Returns currently active touch count.
func get_touch_count() -> int:
	return _touch_points.size()

## Returns current gesture name.
func get_current_gesture() -> String:
	return _current_gesture

## Triggers haptic feedback on mobile platforms.
func trigger_haptic(strength: float = -1.0) -> void:
	if not _config.haptic_enabled:
		return
	if not OS.has_feature("mobile"):
		return
	var resolved_strength: float = strength if strength >= 0.0 else _config.haptic_intensity
	Input.vibrate_handheld(int(clamp(resolved_strength, 0.0, 1.0) * 100.0))

func _on_pointer_pressed(event: Object) -> void:
	var index: int = event.index
	_touch_points[index] = event.position
	_touch_start_positions[index] = event.position
	_gesture_start_time[index] = float(Time.get_ticks_msec()) / 1000.0
	if _touch_points.size() == 1:
		_pending_long_press_index = index
		if _long_press_timer != null:
			_long_press_timer.start(_config.long_press_duration)
	else:
		_pending_long_press_index = -1
		if _long_press_timer != null:
			_long_press_timer.stop()
	if _touch_points.size() == 2:
		_current_gesture = "pinch"

func _on_pointer_dragged(event: Object) -> void:
	var index: int = event.index
	if not _touch_points.has(index):
		return
	var start_position: Vector2 = _touch_start_positions.get(index, event.position)
	var distance: float = event.position.distance_to(start_position)
	if distance > float(_config.long_press_drag_threshold) and _long_press_timer != null:
		_long_press_timer.stop()
		_pending_long_press_index = -1
	if distance > float(_config.drag_threshold) and not _is_dragging:
		_is_dragging = true
		_current_gesture = "drag"
		drag_started.emit(event.position, index)
		gesture_detected.emit("drag_start", {"position": event.position, "index": index})
	if _is_dragging:
		drag_updated.emit(event.position, event.relative, index)
		gesture_detected.emit("drag", {"position": event.position, "relative": event.relative, "index": index})
	if _touch_points.size() == 2:
		_emit_pinch()
	_touch_points[index] = event.position

func _on_pointer_released(event: Object) -> void:
	var index: int = event.index
	if not _touch_points.has(index):
		return
	var started_at: float = _gesture_start_time.get(index, float(Time.get_ticks_msec()) / 1000.0)
	var duration: float = float(Time.get_ticks_msec()) / 1000.0 - started_at
	var start_position: Vector2 = _touch_start_positions.get(index, event.position)
	var distance: float = event.position.distance_to(start_position)
	if _is_dragging:
		drag_ended.emit(event.position, index)
		gesture_detected.emit("drag_end", {"position": event.position, "index": index})
	if duration < _config.tap_max_duration and distance < float(_config.drag_threshold):
		tap_detected.emit(event.position, index)
		gesture_detected.emit("tap", {"position": event.position, "index": index})
		_check_for_double_tap(event.position)
	elif duration < _config.swipe_max_time and distance > float(_config.swipe_min_distance):
		var direction: Vector2 = (event.position - start_position).normalized()
		var speed: float = distance / duration if duration > 0.0 else distance
		swipe_detected.emit(direction, speed)
		gesture_detected.emit("swipe", {"direction": direction, "speed": speed})
	_touch_points.erase(index)
	_touch_start_positions.erase(index)
	_gesture_start_time.erase(index)
	if _touch_points.is_empty():
		_current_gesture = ""
		_is_dragging = false
		_pending_long_press_index = -1
		if _long_press_timer != null:
			_long_press_timer.stop()

func _emit_pinch() -> void:
	if _touch_points.size() != 2:
		return
	var points: Array[Vector2] = _touch_points.values()
	var start_points: Array[Vector2] = _touch_start_positions.values()
	if points.size() != 2 or start_points.size() != 2:
		return
	var start_distance: float = start_points[0].distance_to(start_points[1])
	if start_distance <= 0.0:
		return
	var current_distance: float = points[0].distance_to(points[1])
	var scale_delta: float = current_distance / start_distance
	pinch_detected.emit(scale_delta)
	gesture_detected.emit("pinch", {"scale": scale_delta})

func _on_long_press_timeout() -> void:
	if _touch_points.size() != 1:
		return
	if _is_dragging:
		return
	if _pending_long_press_index == -1:
		return
	if not _touch_points.has(_pending_long_press_index):
		return
	var position: Vector2 = _touch_points[_pending_long_press_index]
	long_press_detected.emit(position)
	gesture_detected.emit("long_press", {"position": position, "index": _pending_long_press_index})

func _check_for_double_tap(position: Vector2) -> void:
	var now_seconds: float = float(Time.get_ticks_msec()) / 1000.0
	var elapsed: float = now_seconds - _last_tap_time
	if elapsed <= _config.double_tap_max_delay:
		if position.distance_to(_last_tap_position) < float(_config.drag_threshold * 2):
			double_tap_detected.emit(position)
			gesture_detected.emit("double_tap", {"position": position})
	_last_tap_time = now_seconds
	_last_tap_position = position
