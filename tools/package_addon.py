#!/usr/bin/env python3
"""Build the deterministic, closed-manifest GDAM release ZIP."""

import hashlib
import pathlib
import stat
import sys
import zipfile

FILES = (
    "autoload.gd",
    "autoload.gd.uid",
    "plugin.cfg",
    "plugin.gd",
    "plugin.gd.uid",
    "src/gesture_recognizer_module.gd",
    "src/gesture_recognizer_module.gd.uid",
    "src/pointer_unifier_module.gd",
    "src/pointer_unifier_module.gd.uid",
)


def sha256(path: pathlib.Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def main() -> int:
    root = pathlib.Path(__file__).resolve().parents[1]
    addon = root / "addon"
    actual = tuple(sorted(path.relative_to(addon).as_posix() for path in addon.rglob("*") if path.is_file() or path.is_symlink()))
    if actual != tuple(sorted(FILES)):
        raise SystemExit(f"closed addon manifest mismatch\nexpected={sorted(FILES)}\nactual={list(actual)}")
    for relative in FILES:
        path = addon / relative
        if path.is_symlink() or not path.is_file():
            raise SystemExit(f"release member must be a regular non-symlink file: {relative}")

    dist = root / "dist"
    dist.mkdir(exist_ok=True)
    archive = dist / "@aviorstudio_gd-gesture.zip"
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as output:
        for relative in sorted(FILES):
            info = zipfile.ZipInfo(relative, date_time=(1980, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            output.writestr(info, (addon / relative).read_bytes())
    checksum = sha256(archive)
    (dist / f"{archive.name}.sha256").write_text(f"{checksum}  {archive.name}\n", encoding="utf-8")
    print(f"PACKAGE_ZIP={archive}")
    print(f"PACKAGE_SHA256={checksum}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
