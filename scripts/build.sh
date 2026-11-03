#!/usr/bin/env bash
set -euo pipefail
python3 scripts/package_addon.py
python3 scripts/test_package.py
python3 scripts/test_release_version.py
