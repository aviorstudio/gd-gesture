## Detects high-level gestures from normalized, per-pointer events.
class_name GestureRecognizerModule
extends RefCounted

const PointerUnifierModule = preload("pointer_unifier_module.gd")

class GestureConfig extends RefCounted:
	var tap_max_duration: float = 0.2
	var long_press_duration: float = 0.5
	var drag_threshold: int = 10
	var swipe_min_distance: int = 50
	var swipe_max_time: float = 0.3
	var double_tap_max_delay: float = 0.3
	var haptic_enabled: bool = true
	var haptic_intensity: float = 0.3
	var long_press_drag_threshold: int = 30

signal gesture_detected(gesture_type: String, data: Dictionary)
signal tap_detected(position: Vector2, index: int)
signal double_tap_detected(position: Vector2)
signal long_press_detected(position: Vector2)
signal swipe_detected(direction: Vector2, speed: float)
signal drag_started(position: Vector2, index: int)
signal drag_updated(position: Vector2, relative: Vector2, index: int)
signal drag_ended(position: Vector2, index: int)
## Absolute scale from the distance at the start of the two-pointer pinch.
signal pinch_detected(scale: float)
## Emitted for cancellation; canceled pointers never emit completion gestures.
signal gesture_canceled(index: int, reason: String)

var _owner: Node = null
var _config := GestureConfig.new()
var _touch_points: Dictionary[int, Vector2] = {}
var _gesture_start_ms: Dictionary[int, int] = {}
var _touch_start_positions: Dictionary[int, Vector2] = {}
var _pointer_devices: Dictionary[int, String] = {}
var _dragging: Dictionary[int, bool] = {}
var _multi_pointer_participant: Dictionary[int, bool] = {}
var _long_press_generation: Dictionary[int, int] = {}
var _next_long_press_generation: int = 0
var _last_taps: Dictionary[String, Dictionary] = {}
var _pinch_start_distance: float = 0.0

func setup(owner: Node, config: GestureConfig = null) -> void:
	cancel_all("setup")
	_last_taps.clear()
	_owner = owner
	if config != null:
		_config = config

func process_pointer_event(event: Object) -> void:
	if event == null:
		return
	match event.event_type:
		"press": _on_pointer_pressed(event)
		"drag": _on_pointer_dragged(event)
		"release": _on_pointer_released(event)
		"cancel": _on_pointer_canceled(event)

func cancel_all(reason: String = "canceled") -> void:
	for index in _touch_points.keys():
		_cancel_pointer(int(index), reason)
	_touch_points.clear()
	_touch_start_positions.clear()
	_gesture_start_ms.clear()
	_pointer_devices.clear()
	_dragging.clear()
	_multi_pointer_participant.clear()
	_pinch_start_distance = 0.0

func get_touch_count() -> int:
	return _touch_points.size()

func get_current_gesture() -> String:
	if _touch_points.size() == 2:
		return "pinch"
	if not _dragging.is_empty():
		return "drag"
	return ""

func trigger_haptic(strength: float = -1.0) -> void:
	if not _config.haptic_enabled or not OS.has_feature("mobile"):
		return
	var resolved_strength: float = strength if strength >= 0.0 else _config.haptic_intensity
	Input.vibrate_handheld(int(clamp(resolved_strength, 0.0, 1.0) * 100.0))

func _on_pointer_pressed(event: Object) -> void:
	var index: int = event.index
	if _touch_points.has(index):
		_cancel_pointer(index, "replaced")
	_touch_points[index] = event.position
	_touch_start_positions[index] = event.position
	_gesture_start_ms[index] = event.timestamp_ms
	_pointer_devices[index] = event.device
	_start_long_press(index)
	if _touch_points.size() > 1:
		for active_index in _touch_points.keys():
			_multi_pointer_participant[int(active_index)] = true
		_cancel_all_long_presses()
	if _touch_points.size() == 2:
		_pinch_start_distance = _current_pinch_distance()
	elif _touch_points.size() > 2:
		_pinch_start_distance = 0.0

func _on_pointer_dragged(event: Object) -> void:
	var index: int = event.index
	if not _touch_points.has(index):
		return
	# The moved point is committed before pinch calculation (fieldsofrevik#144).
	_touch_points[index] = event.position
	var start_position: Vector2 = _touch_start_positions[index]
	var distance: float = event.position.distance_to(start_position)
	if distance > float(_config.long_press_drag_threshold):
		_cancel_long_press(index)
	if distance > float(_config.drag_threshold) and not _dragging.has(index):
		_dragging[index] = true
		drag_started.emit(event.position, index)
		gesture_detected.emit("drag_start", {"position": event.position, "index": index})
	if _dragging.has(index):
		drag_updated.emit(event.position, event.relative, index)
		gesture_detected.emit("drag", {"position": event.position, "relative": event.relative, "index": index})
	if _touch_points.size() == 2:
		_emit_pinch()

func _on_pointer_released(event: Object) -> void:
	var index: int = event.index
	if not _touch_points.has(index):
		return
	var duration: float = float(maxi(0, event.timestamp_ms - int(_gesture_start_ms[index]))) / 1000.0
	var start_position: Vector2 = _touch_start_positions[index]
	var distance: float = event.position.distance_to(start_position)
	if _dragging.has(index):
		drag_ended.emit(event.position, index)
		gesture_detected.emit("drag_end", {"position": event.position, "index": index})
	if not _multi_pointer_participant.has(index) and duration < _config.tap_max_duration and distance < float(_config.drag_threshold):
		tap_detected.emit(event.position, index)
		gesture_detected.emit("tap", {"position": event.position, "index": index})
		_check_for_double_tap(event)
	elif not _multi_pointer_participant.has(index) and duration < _config.swipe_max_time and distance > float(_config.swipe_min_distance):
		var direction: Vector2 = (event.position - start_position).normalized()
		var speed: float = distance / duration if duration > 0.0 else distance
		swipe_detected.emit(direction, speed)
		gesture_detected.emit("swipe", {"direction": direction, "speed": speed, "index": index})
	_remove_pointer(index)

func _on_pointer_canceled(event: Object) -> void:
	if _touch_points.has(event.index):
		_cancel_pointer(event.index, event.cancel_reason if not event.cancel_reason.is_empty() else "canceled")

func _cancel_pointer(index: int, reason: String) -> void:
	if not _touch_points.has(index):
		return
	_cancel_long_press(index)
	gesture_canceled.emit(index, reason)
	gesture_detected.emit("cancel", {"index": index, "reason": reason})
	_remove_pointer(index)

func _remove_pointer(index: int) -> void:
	var previous_size: int = _touch_points.size()
	_touch_points.erase(index)
	_touch_start_positions.erase(index)
	_gesture_start_ms.erase(index)
	_pointer_devices.erase(index)
	_dragging.erase(index)
	_multi_pointer_participant.erase(index)
	_cancel_long_press(index)
	_long_press_generation.erase(index)
	if _touch_points.size() < 2:
		_pinch_start_distance = 0.0
	elif _touch_points.size() == 2 and previous_size > 2:
		_pinch_start_distance = _current_pinch_distance()

func _current_pinch_distance() -> float:
	var points: Array = _touch_points.values()
	return points[0].distance_to(points[1]) if points.size() == 2 else 0.0

func _emit_pinch() -> void:
	if _pinch_start_distance <= 0.0:
		return
	var scale: float = _current_pinch_distance() / _pinch_start_distance
	pinch_detected.emit(scale)
	gesture_detected.emit("pinch", {"scale": scale})

func _start_long_press(index: int) -> void:
	_cancel_long_press(index)
	if _owner == null or not _owner.is_inside_tree() or _owner.get_tree() == null:
		return
	_next_long_press_generation += 1
	var generation: int = _next_long_press_generation
	_long_press_generation[index] = generation
	var timer: SceneTreeTimer = _owner.get_tree().create_timer(_config.long_press_duration)
	timer.timeout.connect(func() -> void:
		if int(_long_press_generation.get(index, 0)) == generation and _touch_points.size() == 1 and _touch_points.has(index) and not _dragging.has(index):
			var position: Vector2 = _touch_points[index]
			long_press_detected.emit(position)
			gesture_detected.emit("long_press", {"position": position, "index": index})
	, CONNECT_ONE_SHOT)

func _cancel_long_press(index: int) -> void:
	_next_long_press_generation += 1
	_long_press_generation[index] = _next_long_press_generation

func _cancel_all_long_presses() -> void:
	for index in _touch_points.keys():
		_cancel_long_press(int(index))

func _check_for_double_tap(event: Object) -> void:
	var key: String = "%s:%d" % [event.device, event.index]
	var previous: Dictionary = _last_taps.get(key, {})
	if not previous.is_empty():
		var elapsed: float = float(event.timestamp_ms - int(previous.time_ms)) / 1000.0
		if elapsed >= 0.0 and elapsed <= _config.double_tap_max_delay and event.position.distance_to(previous.position) < float(_config.drag_threshold * 2):
			double_tap_detected.emit(event.position)
			gesture_detected.emit("double_tap", {"position": event.position, "index": event.index})
	_last_taps[key] = {"time_ms": event.timestamp_ms, "position": event.position}
