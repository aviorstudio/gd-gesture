#!/usr/bin/env bash
set -euo pipefail

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
mapfile -t release_fields < <(python3 - "$script_dir/godot-release.json" <<'PY'
import json, re, sys
release = json.load(open(sys.argv[1], encoding="utf-8"))
assert re.fullmatch(r"\d+\.\d+\.\d+", release["version"])
assert re.fullmatch(r"[0-9a-f]{128}", release["binary_sha512"])
assert re.fullmatch(r"[0-9a-f]{128}", release["templates_sha512"])
assert release["binary_archive"] == f"Godot_v{release['version']}-stable_linux.x86_64.zip"
assert release["templates_archive"] == f"Godot_v{release['version']}-stable_export_templates.tpz"
print(release["version"])
print(release["binary_archive"])
print(release["binary_sha512"])
print(release["templates_archive"])
print(release["templates_sha512"])
PY
)
version=${release_fields[0]}
: "${RUNNER_TEMP:?RUNNER_TEMP is required}"
archive_dir=${GODOT_ARCHIVE_DIR:-$RUNNER_TEMP/gd-gesture-godot-downloads}
binary_dir=${GODOT_BINARY_DIR:-$RUNNER_TEMP/gd-gesture-godot-bin}
mkdir -p "$archive_dir" "$binary_dir"
fetch_verified() {
  local name=$1 checksum=$2 archive="$archive_dir/$1"
  if [[ ! -f "$archive" ]]; then
    curl -fsSL --connect-timeout 15 --max-time 600 --retry 3 \
      "https://github.com/godotengine/godot/releases/download/$version-stable/$name" -o "$archive.part"
    mv "$archive.part" "$archive"
  fi
  echo "$checksum  $archive" | sha512sum --check --strict
}
fetch_verified "${release_fields[1]}" "${release_fields[2]}"
archive="$archive_dir/${release_fields[1]}"
unzip -oq "$archive" -d "$binary_dir"
install -m 755 "$binary_dir/${release_fields[1]%.zip}" "$binary_dir/godot"
if [[ -n ${GITHUB_PATH:-} ]]; then
  echo "$binary_dir" >> "$GITHUB_PATH"
fi
"$binary_dir/godot" --version
if [[ ${INSTALL_TEMPLATES:-false} == true ]]; then
  fetch_verified "${release_fields[3]}" "${release_fields[4]}"
  template_dir="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$version.stable"
  mkdir -p "$template_dir"
  unzip -ojq "$archive_dir/${release_fields[3]}" -d "$template_dir"
fi
