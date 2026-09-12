#!/usr/bin/env python3
"""Reject unsafe/unexpected ZIP members and report installed-byte identity."""

import hashlib
import pathlib
import shutil
import stat
import sys
import zipfile

from package_addon import FILES, sha256


def tree_digest(root: pathlib.Path) -> str:
    digest = hashlib.sha256()
    for path in sorted(root.rglob("*")):
        if path.is_symlink():
            raise ValueError(f"installed tree contains symlink: {path}")
        if path.is_file():
            relative = path.relative_to(root).as_posix()
            digest.update(relative.encode() + b"\0" + path.read_bytes() + b"\0")
    return digest.hexdigest()


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        raise SystemExit("usage: verify_package.py ARCHIVE EXTRACT_DIR")
    archive, destination = map(pathlib.Path, argv)
    expected = sorted(FILES)
    if not archive.is_file():
        raise SystemExit(f"missing package: {archive}")
    if destination.exists():
        shutil.rmtree(destination)
    destination.mkdir(parents=True)
    with zipfile.ZipFile(archive) as package:
        names = [info.filename for info in package.infolist()]
        if sorted(names) != expected or len(names) != len(set(names)):
            raise SystemExit(f"ZIP closed manifest mismatch: {names}")
        for info in package.infolist():
            member = pathlib.PurePosixPath(info.filename)
            mode = info.external_attr >> 16
            if member.is_absolute() or ".." in member.parts or stat.S_ISLNK(mode):
                raise SystemExit(f"unsafe ZIP member: {info.filename}")
        package.extractall(destination)
    actual = sorted(path.relative_to(destination).as_posix() for path in destination.rglob("*") if path.is_file())
    if actual != expected:
        raise SystemExit(f"installed closed manifest mismatch: {actual}")
    print(f"VERIFIED_ZIP_SHA256={sha256(archive)}")
    print(f"INSTALLED_TREE_SHA256={tree_digest(destination)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
