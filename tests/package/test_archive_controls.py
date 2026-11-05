#!/usr/bin/env python3
"""Negative controls for release archive validation."""

import contextlib
import io
import pathlib
import stat
import tempfile
import unittest
import zipfile

import importlib.util
import os
ROOT = pathlib.Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("shared_addon_package", pathlib.Path(os.environ["TOOLS_ROOT"]) / "helpers/addon-package.py")
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)
MANIFEST = ROOT / "package-manifest.txt"


class PackageControls(unittest.TestCase):
    def verify(self, members: dict[str, bytes | tuple[bytes, int]]) -> int:
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            archive = root / "control.zip"
            with zipfile.ZipFile(archive, "w") as output:
                for name, value in members.items():
                    data, mode = value if isinstance(value, tuple) else (value, stat.S_IFREG | 0o644)
                    info = zipfile.ZipInfo(name)
                    info.external_attr = mode << 16
                    output.writestr(info, data)
            with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
                try:
                    package.verify(archive, MANIFEST)
                    return 0
                except (ValueError, OSError):
                    return 1

    def test_restored_complete_archive_passes(self) -> None:
        self.assertEqual(self.verify({name: b"x" for name in package.manifest_files(MANIFEST)}), 0)

    def test_missing_and_unexpected_members_fail(self) -> None:
        self.assertNotEqual(self.verify({"plugin.cfg": b"x"}), 0)
        members = {name: b"x" for name in package.manifest_files(MANIFEST)}
        members["tests/not-for-release.gd"] = b"x"
        self.assertNotEqual(self.verify(members), 0)

    def test_traversal_and_symlink_fail(self) -> None:
        self.assertNotEqual(self.verify({"../plugin.cfg": b"x"}), 0)
        self.assertNotEqual(self.verify({"plugin.cfg": (b"target", stat.S_IFLNK | 0o777)}), 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
