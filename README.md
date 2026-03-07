# gd-gesture

Game-agnostic gesture primitives for Godot 4.

This addon is intentionally focused on input normalization and gesture detection primitives.

## Installation

### Via gdpm
`gdpm install @aviorstudio/gd-gesture`

### Manual
Copy this directory into `addons/@aviorstudio_gd-gesture/` and enable the plugin.

## Quick Start

```gdscript
const GestureRecognizerModule = preload("res://addons/@aviorstudio_gd-gesture/src/gesture_recognizer_module.gd")
const PointerUnifierModule = preload("res://addons/@aviorstudio_gd-gesture/src/pointer_unifier_module.gd")

var pointer_unifier: PointerUnifierModule = PointerUnifierModule.new()
var gesture_recognizer: GestureRecognizerModule = GestureRecognizerModule.new()
gesture_recognizer.setup(self)

pointer_unifier.pointer_pressed.connect(func(event: PointerUnifierModule.PointerEvent) -> void:
	gesture_recognizer.process_pointer_event(event)
)
```

## API Reference

- `PointerUnifierModule`: normalize mouse/touch into typed pointer events.
- `GestureRecognizerModule`: tap/double-tap/long-press/swipe/drag/pinch detection.
- `GdGestureAutoload`: optional autoload facade that wires both modules.

## Scope Boundary

- In scope: pointer normalization and gesture recognition.
- Out of scope: UI action mapping, scene navigation triggers, and gameplay command orchestration.

## Testing

`./tests/test.sh`

## License

MIT