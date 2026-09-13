#!/usr/bin/env bash
set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
godot=${GODOT_BIN:-godot}
archive=${1:-$root/dist/@aviorstudio_gd-gesture.zip}
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/addons/@aviorstudio_gd-gesture" "$fixture/addons/lifecycle_controller" "$fixture/lifecycle"
python3 "$root/tools/verify_package.py" "$archive" "$fixture/addons/@aviorstudio_gd-gesture"
cp "$root/tests/lifecycle/smoke.gd" "$fixture/lifecycle/"
cp "$root/tests/lifecycle/controller/"* "$fixture/addons/lifecycle_controller/"
cat > "$fixture/project.godot" <<'EOF'
[application]
config/name="gd-gesture packaged lifecycle"

[editor_plugins]
enabled=PackedStringArray("res://addons/lifecycle_controller/plugin.cfg")

[rendering]
renderer/rendering_method="gl_compatibility"
EOF

run_test() {
  local sentinel=$1; shift
  python3 "$root/tools/run_godot_test.py" --sentinel "$sentinel" "$@"
}

GD_GESTURE_PLUGIN_ENABLED=true run_test \
  "PASS gd-gesture set_plugin_enabled assertions=2" \
  "$godot" --headless --editor --path "$fixture"
# Restart the editor and prove the plugin/autoload can be enabled again from
# the installed bytes before exercising the runtime module.
GD_GESTURE_PLUGIN_ENABLED=true run_test \
  "PASS gd-gesture set_plugin_enabled assertions=2" \
  "$godot" --headless --editor --path "$fixture"
run_test "PASS gd-gesture packaged_smoke assertions=1" \
  "$godot" --headless --path "$fixture" --script "$fixture/lifecycle/smoke.gd"
web=$(mktemp -d)
trap 'rm -rf "$fixture" "$web"' EXIT
mkdir -p "$web/addons/@aviorstudio_gd-gesture"
python3 "$root/tools/verify_package.py" "$archive" "$web/addons/@aviorstudio_gd-gesture"
cp "$root/tests/web/playground.gd" "$root/tests/web/playground.tscn" "$root/tests/web/export_presets.cfg" "$web/"
cat > "$web/project.godot" <<'EOF'
[application]
config/name="gd-gesture web playground"
run/main_scene="res://playground.tscn"

[display/window]
size/viewport_width=960
size/viewport_height=540
size/window_width_override=960
size/window_height_override=540

[rendering]
renderer/rendering_method="gl_compatibility"
EOF
rm -rf "$root/dist/playground"
mkdir -p "$root/dist/playground"
"$godot" --headless --path "$web" --export-release Web "$root/dist/playground/index.html"
test -s "$root/dist/playground/index.html"
test -s "$root/dist/playground/index.wasm"
GD_GESTURE_PLUGIN_ENABLED=false run_test \
  "PASS gd-gesture set_plugin_enabled assertions=1" \
  "$godot" --headless --editor --path "$fixture"
run_test "PASS gd-gesture lifecycle_cleanup assertions=2" \
  python3 - "$fixture/project.godot" <<'PY'
import pathlib, sys
project = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
assert "@aviorstudio_gd-gesture" not in project
assert "autoload/GdGesture" not in project
print("PASS gd-gesture lifecycle_cleanup assertions=2")
PY

# A consumer-owned singleton with the same name is never replaced or deleted.
consumer=$(mktemp -d)
trap 'rm -rf "$fixture" "$web" "$consumer"' EXIT
mkdir -p "$consumer/addons/@aviorstudio_gd-gesture" "$consumer/addons/lifecycle_controller"
python3 "$root/tools/verify_package.py" "$archive" "$consumer/addons/@aviorstudio_gd-gesture"
cp "$root/tests/lifecycle/controller/"* "$consumer/addons/lifecycle_controller/"
cat > "$consumer/consumer.gd" <<'EOF'
extends Node
EOF
cat > "$consumer/project.godot" <<'EOF'
[application]
config/name="gd-gesture consumer ownership"

[autoload]
GdGesture="*res://consumer.gd"

[editor_plugins]
enabled=PackedStringArray("res://addons/lifecycle_controller/plugin.cfg")

[rendering]
renderer/rendering_method="gl_compatibility"
EOF
GD_GESTURE_PLUGIN_ENABLED=true run_test \
  "PASS gd-gesture set_plugin_enabled assertions=2" \
  "$godot" --headless --editor --path "$consumer"
GD_GESTURE_PLUGIN_ENABLED=false run_test \
  "PASS gd-gesture set_plugin_enabled assertions=1" \
  "$godot" --headless --editor --path "$consumer"
run_test "PASS gd-gesture consumer_ownership assertions=1" \
  python3 - "$consumer/project.godot" <<'PY'
import pathlib, sys
project = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
assert 'GdGesture="*res://consumer.gd"' in project
print("PASS gd-gesture consumer_ownership assertions=1")
PY
