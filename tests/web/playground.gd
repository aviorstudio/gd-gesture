extends Node2D

const PointerUnifierModule = preload("res://addons/@aviorstudio_gd-gesture/src/pointer_unifier_module.gd")
const GestureRecognizerModule = preload("res://addons/@aviorstudio_gd-gesture/src/gesture_recognizer_module.gd")

var pointer := PointerUnifierModule.new()
var recognizer := GestureRecognizerModule.new()
var status := "Ready — tap, drag, or pinch"
var event_count := 0

func _ready() -> void:
	recognizer.setup(self)
	pointer.pointer_pressed.connect(recognizer.process_pointer_event)
	pointer.pointer_dragged.connect(recognizer.process_pointer_event)
	pointer.pointer_released.connect(recognizer.process_pointer_event)
	pointer.pointer_canceled.connect(recognizer.process_pointer_event)
	recognizer.gesture_detected.connect(_on_gesture)
	queue_redraw()

func _input(event: InputEvent) -> void:
	pointer.process_input(event)

func _on_gesture(kind: String, data: Dictionary) -> void:
	event_count += 1
	status = "%s  •  event %d  •  %s" % [kind, event_count, str(data)]
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("101725"))
	draw_circle(Vector2(480, 290), 130, Color("263d66"))
	draw_circle(Vector2(480, 290), 110, Color("172846"))
	draw_string(ThemeDB.fallback_font, Vector2(54, 80), "GD GESTURE", HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Color("7dd3fc"))
	draw_string(ThemeDB.fallback_font, Vector2(54, 125), "Godot 4.7.2 packaged web playground", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("cbd5e1"))
	draw_string(ThemeDB.fallback_font, Vector2(54, 475), status, HORIZONTAL_ALIGNMENT_LEFT, 850, 20, Color("f8fafc"))
	draw_string(ThemeDB.fallback_font, Vector2(382, 296), "INTERACT", HORIZONTAL_ALIGNMENT_CENTER, 196, 22, Color("f8fafc"))
