#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
tools="$(python3 scripts/engineering-bootstrap.py)"
export XDG_DATA_HOME="$PWD/.artifacts/godot-data"
python3 scripts/profile-godot-install.py "$tools"
bash scripts/profile-lint.sh
