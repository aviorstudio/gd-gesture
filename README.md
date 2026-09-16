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

**Correction (https://github.com/aviorstudio/fieldsofrevik/issues/144):**
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

**Correction (fieldsofrevik#144):** CI and release both run the required
Godot 4.7.2 suite, fail on runtime/log errors and unreachable assertion
sentinels, and verify the exact deterministic release ZIP through a clean
editor enable, restart, smoke, disable, and restart lifecycle. Earlier text
said CI ran the script “when available,” which understated that a missing suite
must fail and did not describe release coverage.

The shared CI/Release test action also validates GDAM action inputs against
immutable upstream metadata, including negative/restored typo and unsupported
`publish.version` controls. See [the fixture documentation](tests/fixtures/gdam-actions/README.md)
for the local Python test command and provenance. `install.version` remains a
valid CLI selection input; registry publication uses the exact release `tag`.

## License

MIT
