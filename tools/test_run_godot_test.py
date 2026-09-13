#!/usr/bin/env python3
"""Negative/restored controls for the fail-safe Godot runner."""

import contextlib
import io
import os
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).parent))
from run_godot_test import run


class RunnerUnitControls(unittest.TestCase):
    sentinel = "PASS gd-gesture control assertions=1"

    def execute(self, source: str, timeout: float = 2.0) -> int:
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return run([sys.executable, "-c", source], self.sentinel, timeout)

    def test_restored_success_and_reachable_assertion(self) -> None:
        self.assertEqual(self.execute(f"print({self.sentinel!r})"), 0)

    def test_runtime_error_with_zero_exit_fails(self) -> None:
        self.assertNotEqual(self.execute(f"print('ERROR: control'); print({self.sentinel!r})"), 0)

    def test_assertion_failure_with_later_success_fails(self) -> None:
        self.assertNotEqual(self.execute(f"print('FAIL: assertion'); print({self.sentinel!r})"), 0)

    def test_parse_load_failure_without_sentinel_fails(self) -> None:
        self.assertNotEqual(self.execute("raise SyntaxError('control')"), 0)

    def test_timeout_fails(self) -> None:
        self.assertNotEqual(self.execute("import time; time.sleep(2)", 0.01), 0)

    def test_missing_command_fails(self) -> None:
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            self.assertNotEqual(run(["/definitely/missing/gd-gesture-test"], self.sentinel), 0)

    def test_missing_and_duplicate_sentinels_fail(self) -> None:
        self.assertNotEqual(self.execute("print('ordinary output')"), 0)
        self.assertNotEqual(self.execute(f"print({self.sentinel!r}); print({self.sentinel!r})"), 0)


class GodotProcessControls(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.godot = os.environ.get("GODOT_BIN", "godot")
        cls.root = pathlib.Path(__file__).resolve().parents[1]
        cls.fixtures = cls.root / "tests" / "runner_fixtures"

    def execute(self, fixture: str, timeout: float = 5.0) -> int:
        sentinel = "PASS gd-gesture runner_success assertions=1"
        argv = [self.godot, "--headless", "--path", str(self.root), "--script", str(self.fixtures / fixture)]
        with contextlib.redirect_stdout(io.StringIO()), contextlib.redirect_stderr(io.StringIO()):
            return run(argv, sentinel, timeout)

    def test_restored_godot_fixture_passes(self) -> None:
        self.assertEqual(self.execute("success.gd"), 0)

    def test_push_error_then_zero_exit_fails(self) -> None:
        self.assertNotEqual(self.execute("runtime_error.gd"), 0)

    def test_assertion_exit_overwrite_fails(self) -> None:
        self.assertNotEqual(self.execute("assertion_overwrite.gd"), 0)

    def test_parse_failure_is_not_a_green_skip(self) -> None:
        self.assertNotEqual(self.execute("parse_error.gd"), 0)

    def test_hanging_godot_fails(self) -> None:
        self.assertNotEqual(self.execute("timeout.gd", 0.25), 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
