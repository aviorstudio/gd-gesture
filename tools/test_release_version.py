#!/usr/bin/env python3
"""Negative/restored controls for release identity resolution."""

import unittest

from resolve_release import resolve


class ReleaseVersionControls(unittest.TestCase):
    def test_new_patch_release(self) -> None:
        self.assertEqual(resolve("0.0.2", "patch", {"v0.0.1": "old"}, "head"), ("0.0.2", "v0.0.2"))

    def test_resume_same_head_release(self) -> None:
        self.assertEqual(resolve("0.0.2", "patch", {"v0.0.1": "old", "v0.0.2": "head"}, "head"), ("0.0.2", "v0.0.2"))

    def test_wrong_existing_tag_identity_fails(self) -> None:
        with self.assertRaises(ValueError):
            resolve("0.0.2", "patch", {"v0.0.2": "other"}, "head")

    def test_wrong_new_version_fails(self) -> None:
        with self.assertRaises(ValueError):
            resolve("9.9.9", "patch", {"v0.0.1": "old"}, "head")


if __name__ == "__main__":
    unittest.main(verbosity=2)
