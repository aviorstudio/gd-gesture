# gd-gesture

Game-agnostic gesture primitives for Godot 4.

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

## Testing

`./tests/test.sh`

## License

MIT