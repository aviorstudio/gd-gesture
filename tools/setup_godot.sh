#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mapfile -t release_fields < <(python3 - "$script_dir/godot-release.json" <<'PY'
import json, re, sys
release = json.load(open(sys.argv[1], encoding="utf-8"))
assert re.fullmatch(r"\d+\.\d+\.\d+", release["version"])
assert re.fullmatch(r"[0-9a-f]{128}", release["binary_sha512"])
assert release["binary_archive"] == f"Godot_v{release['version']}-stable_linux.x86_64.zip"
print(release["version"])
print(release["binary_archive"])
print(release["binary_sha512"])
PY
)
version=${release_fields[0]}
: "${RUNNER_TEMP:?RUNNER_TEMP is required}"
archive_dir=${GODOT_ARCHIVE_DIR:-$RUNNER_TEMP/gd-gesture-godot-downloads}
binary_dir=${GODOT_BINARY_DIR:-$RUNNER_TEMP/gd-gesture-godot-bin}
archive="$archive_dir/${release_fields[1]}"
mkdir -p "$archive_dir" "$binary_dir"
if [[ ! -f "$archive" ]]; then
  curl -fsSL --connect-timeout 15 --max-time 600 --retry 3 \
    "https://github.com/godotengine/godot/releases/download/$version-stable/${release_fields[1]}" \
    -o "$archive.part"
  mv "$archive.part" "$archive"
fi
echo "${release_fields[2]}  $archive" | sha512sum --check --strict
unzip -oq "$archive" -d "$binary_dir"
install -m 755 "$binary_dir/${release_fields[1]%.zip}" "$binary_dir/godot"
if [[ -n ${GITHUB_PATH:-} ]]; then
  echo "$binary_dir" >> "$GITHUB_PATH"
fi
"$binary_dir/godot" --version
