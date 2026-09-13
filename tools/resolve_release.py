#!/usr/bin/env python3
"""Resolve a new or safely resumable release from immutable git state."""

import pathlib
import re
import subprocess
import sys


def resolve(plugin: str, bump: str, tags: dict[str, str], head: str) -> tuple[str, str]:
    plugin_tag = f"v{plugin}"
    if plugin_tag in tags:
        if tags[plugin_tag] != head:
            raise ValueError(f"{plugin_tag} does not point to release head")
        return plugin, plugin_tag
    versions = [tuple(map(int, match.groups())) for tag in tags if (match := re.fullmatch(r"v(\d+)\.(\d+)\.(\d+)", tag))]
    major, minor, patch = max(versions, default=(0, 0, 0))
    if bump == "major":
        expected = (major + 1, 0, 0)
    elif bump == "minor":
        expected = (major, minor + 1, 0)
    elif bump == "patch":
        expected = (major, minor, patch + 1)
    else:
        raise ValueError(f"unsupported bump: {bump}")
    version = ".".join(map(str, expected))
    if plugin != version:
        raise ValueError(f"plugin version {plugin} does not match next {bump} version {version}")
    return version, f"v{version}"


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        raise SystemExit("usage: resolve_release.py BUMP HEAD_SHA")
    root = pathlib.Path(__file__).resolve().parents[1]
    config = (root / "addon" / "plugin.cfg").read_text(encoding="utf-8")
    plugin_match = re.search(r'^version="([0-9]+\.[0-9]+\.[0-9]+)"$', config, re.MULTILINE)
    if not plugin_match:
        raise SystemExit("invalid plugin version")
    tags = {}
    for tag in subprocess.check_output(["git", "tag", "--list", "v[0-9]*"], cwd=root, text=True).splitlines():
        tags[tag] = subprocess.check_output(["git", "rev-list", "-n", "1", tag], cwd=root, text=True).strip()
    try:
        version, tag = resolve(plugin_match.group(1), argv[0], tags, argv[1])
    except ValueError as error:
        raise SystemExit(str(error)) from error
    print(version)
    print(tag)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
