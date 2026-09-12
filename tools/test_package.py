#!/usr/bin/env python3
"""Negative controls for release archive validation."""

import contextlib
import io
import pathlib
import stat
import tempfile
import unittest
import zipfile

from verify_package import main


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
                    return main([str(archive), str(root / "installed")])
                except SystemExit:
                    return 1

    def test_missing_and_unexpected_members_fail(self) -> None:
        self.assertNotEqual(self.verify({"plugin.cfg": b"x"}), 0)
        from package_addon import FILES
        members = {name: b"x" for name in FILES}
        members["tests/not-for-release.gd"] = b"x"
        self.assertNotEqual(self.verify(members), 0)

    def test_traversal_and_symlink_fail(self) -> None:
        self.assertNotEqual(self.verify({"../plugin.cfg": b"x"}), 0)
        self.assertNotEqual(self.verify({"plugin.cfg": (b"target", stat.S_IFLNK | 0o777)}), 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
