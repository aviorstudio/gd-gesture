#!/usr/bin/env python3
"""Install the exact caller-owned Godot manifest through verified shared tooling."""
import json
from pathlib import Path
import re
import subprocess
import sys

release = json.loads(Path("tools/godot-release.json").read_text())
version = release["version"]
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    raise ValueError("invalid engine version")
for kind, expected in [("binary", f"Godot_v{version}-stable_linux.x86_64.zip"),
                       ("templates", f"Godot_v{version}-stable_export_templates.tpz")]:
    if release[kind + "_archive"] != expected or not re.fullmatch(r"[a-f0-9]{128}", release[kind + "_sha512"]):
        raise ValueError("invalid reviewed archive identity")
subprocess.run([sys.executable, str(Path(sys.argv[1]) / "helpers/godot-setup.py"),
                "--version", version, "--origin", "godot", "--root", str(Path(".artifacts/godot").resolve()),
                "--binary-checksum", "sha512:" + release["binary_sha512"], "--templates",
                "--templates-checksum", "sha512:" + release["templates_sha512"]], check=True)
