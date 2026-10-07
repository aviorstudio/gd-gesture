#!/usr/bin/env bash
set -euo pipefail
python3 tools/package_addon.py
python3 tools/test_package.py
python3 tools/test_release_version.py
