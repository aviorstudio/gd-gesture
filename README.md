<!-- Generated from private documentation source. Do not edit directly. Source SHA256: 15ce0c37dbde16189ff2c03aa2321af19494ae7e8f77d2ecc7c88dd5dd17c308 -->

# gd-gesture

Recognize taps, swipes, drags, pinches, and long presses in Godot 4.

Use this addon when you want mouse and touch input normalized into one pointer stream, plus reusable gesture detection signals.

## Installation

### Via gdam

`gdam install @aviorstudio/gd-gesture`

### Manual

Copy `addon/` into `res://addons/@aviorstudio_gd-gesture/` and enable the plugin.

## Quick Start

The plugin can install an optional `GdGesture` autoload. Use it when your game wants one global gesture stream.

```gdscript
func _ready() -> void:
	GdGesture.tap_detected.connect(_on_tap_detected)
	GdGesture.swipe_detected.connect(_on_swipe_detected)
	GdGesture.drag_started.connect(_on_drag_started)

func _on_tap_detected(position: Vector2, index: int) -> void:
	print("Pointer ", index, " tapped at ", position)
```

## Manual Module Setup

Use the modules directly when a scene needs isolated input handling or custom thresholds.

```gdscript
const GestureRecognizerModule = preload("res://addons/@aviorstudio_gd-gesture/src/gesture_recognizer_module.gd")
const PointerUnifierModule = preload("res://addons/@aviorstudio_gd-gesture/src/pointer_unifier_module.gd")

var pointer_unifier := PointerUnifierModule.new()
var gesture_recognizer := GestureRecognizerModule.new()

func _ready() -> void:
	gesture_recognizer.setup(self)
	pointer_unifier.pointer_pressed.connect(gesture_recognizer.process_pointer_event)
	pointer_unifier.pointer_dragged.connect(gesture_recognizer.process_pointer_event)
	pointer_unifier.pointer_released.connect(gesture_recognizer.process_pointer_event)
	pointer_unifier.pointer_canceled.connect(gesture_recognizer.process_pointer_event)
```

**Usage note:**
Earlier examples used the nonexistent `pointer_moved` signal and a one-argument
tap callback. The compiled example above uses the actual signal names and the
two-argument `tap_detected(position, index)` contract.

## What You Get

- `PointerUnifierModule`: converts mouse and touch events into typed pointer events.
- `GestureRecognizerModule`: detects tap, double tap, long press, swipe, drag, and pinch.
- `GdGestureAutoload`: optional global facade around both modules.

## Notes

- `PointerUnifierModule.mouse_button` defaults to `MOUSE_BUTTON_LEFT`.
- Each pointer owns its drag state. `pinch_detected(scale)` is the absolute
  current two-pointer distance divided by the distance when the pinch began.
- Feed manual input with `process_input(event, gui_accepted)`. Accepted GUI
  input is ignored; the autoload already uses `_unhandled_input`, after GUI.
- Focus loss, screen cancellation, and teardown emit `pointer_canceled` and
  `gesture_canceled`; canceled contacts cannot later tap, swipe, or long press.
- Synthesized mouse events (`device == -1`) are ignored to avoid duplicate
  mouse/touch recognition.
- Use direct modules for split-screen, editor tools, or scenes with custom gesture thresholds.
- Map gestures to gameplay actions in your own game code.


## License

See `LICENSE`.

## Contributor checks

Install [mise](https://mise.jdx.dev/), then prepare the pinned development helpers and run the complete native gate:

```sh
git clone https://github.com/nicodes/tools.git .ci-tools
git -C .ci-tools checkout --detach f7e243524ce2aa29f299e4c79db33001f72f4a30
mise install
mise run check
```

`mise.toml` owns tool versions and tasks. Engine and template downloads are checksum verified. `mise run build` packages the addon; `mise run test` runs its declared tests. The complete check also validates the installed artifact. Build and test receipts stay in `.artifacts/verification`.
