#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR=$(cd "$SCRIPT_DIR/.." && pwd)
GODOT="${GODOT_BIN:-godot}"
export GODOT_BIN="$GODOT"
python3 "$ROOT_DIR/tools/test_run_godot_test.py"

mapfile -t tests < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name '*_test.gd' -print | sort)
if (( ${#tests[@]} == 0 )); then
    echo "FAIL: no Godot test scripts discovered" >&2
    exit 1
fi
for test in "${tests[@]}"; do
    name=$(basename "$test" .gd)
    echo "Running ${name}.gd..."
    python3 "$ROOT_DIR/tools/run_godot_test.py" \
        --sentinel "PASS gd-gesture $name assertions=" \
        "$GODOT" --headless --path "$ROOT_DIR" --script "$test"
done
