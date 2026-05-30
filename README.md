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

func _on_tap_detected(position: Vector2) -> void:
	print("Tapped at ", position)
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
	pointer_unifier.pointer_moved.connect(gesture_recognizer.process_pointer_event)
	pointer_unifier.pointer_released.connect(gesture_recognizer.process_pointer_event)
```

## What You Get

- `PointerUnifierModule`: converts mouse and touch events into typed pointer events.
- `GestureRecognizerModule`: detects tap, double tap, long press, swipe, drag, and pinch.
- `GdGestureAutoload`: optional global facade around both modules.

## Notes

- `PointerUnifierModule.mouse_button` defaults to `MOUSE_BUTTON_LEFT`.
- Use direct modules for split-screen, editor tools, or scenes with custom gesture thresholds.
- Map gestures to gameplay actions in your own game code.

## Repository Layout

- `addon/`: Godot plugin source packaged for GDAM and manual installation.
- `addon/plugin.cfg`: plugin name, version, description, and entry script.
- `addon/src/`: reusable GDScript modules.
- `tests/`: Godot test project/scripts for addon behavior.
- `.github/workflows/ci.yml`: validates package shape and runs tests.
- `.github/workflows/release.yml`: creates GitHub release ZIPs and publishes to GDAM.

## Versioning And Releases

The version in `addon/plugin.cfg` is the addon package version. Releases are created from `main` with the manual release workflow and plain semver tags like `v0.0.1`; the workflow verifies `plugin.cfg`, builds `@aviorstudio_gd-gesture.zip`, and publishes `@aviorstudio/gd-gesture` to GDAM.

## Testing

Run locally with:

```sh
./tests/test.sh
```

CI runs the same test script when available.

## License

MIT
