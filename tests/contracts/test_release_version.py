#!/usr/bin/env python3
"""Negative/restored controls for release identity resolution."""

import unittest

import importlib.util
import os
from pathlib import Path
spec = importlib.util.spec_from_file_location("shared_github_release", Path(os.environ["TOOLS_ROOT"]) / "helpers/github_release.py")
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)
resolve = release.resolve_version


class ReleaseVersionControls(unittest.TestCase):
    def test_new_patch_release(self) -> None:
        self.assertEqual(resolve("0.0.2", "patch", {"v0.0.1": "a" * 40}, "b" * 40), ("0.0.2", "v0.0.2"))

    def test_resume_same_head_release(self) -> None:
        self.assertEqual(resolve("0.0.2", "patch", {"v0.0.1": "a" * 40, "v0.0.2": "b" * 40}, "b" * 40), ("0.0.2", "v0.0.2"))

    def test_wrong_existing_tag_identity_fails(self) -> None:
        with self.assertRaises(ValueError):
            resolve("0.0.2", "patch", {"v0.0.2": "c" * 40}, "b" * 40)

    def test_wrong_new_version_fails(self) -> None:
        with self.assertRaises(ValueError):
            resolve("9.9.9", "patch", {"v0.0.1": "a" * 40}, "b" * 40)


if __name__ == "__main__":
    unittest.main(verbosity=2)
