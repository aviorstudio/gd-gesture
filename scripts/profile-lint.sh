#!/usr/bin/env bash
set -euo pipefail
export RUNNER_TEMP="${RUNNER_TEMP:-$PWD/.artifacts/tmp}"
venv="$RUNNER_TEMP/action-input-contract-venv"
python3 -m venv "$venv"
"$venv/bin/python" -m pip install --disable-pip-version-check --only-binary=:all: --require-hashes -r .github/action-input-requirements.txt
"$venv/bin/python" tools/test_action_inputs.py
