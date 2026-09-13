#!/usr/bin/env python3
"""Run one Godot test without accepting engine errors or unreachable assertions."""

import os
import re
import subprocess
import sys

ERROR_PATTERN = re.compile(r"(?:SCRIPT ERROR:|(?:^|\n)(?:ERROR:|FAIL:))")


def run(argv: list[str], sentinel: str, timeout_seconds: float = 30.0) -> int:
    if not argv:
        print("FAIL: missing test command", file=sys.stderr)
        return 1
    try:
        result = subprocess.run(
            argv,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout_seconds,
            check=False,
            env={**os.environ, "GODOT_SILENCE_ROOT_WARNING": "1"},
        )
    except (FileNotFoundError, PermissionError) as error:
        print(f"FAIL: cannot execute test command: {error}", file=sys.stderr)
        return 1
    except subprocess.TimeoutExpired as error:
        output = error.stdout or ""
        if isinstance(output, bytes):
            output = output.decode(errors="replace")
        print(output, end="" if output.endswith("\n") else "\n")
        print(f"FAIL: test exceeded {timeout_seconds:g} seconds", file=sys.stderr)
        return 1

    print(result.stdout, end="")
    sentinel_count = result.stdout.count(sentinel)
    if result.returncode != 0:
        print(f"FAIL: test exited {result.returncode}", file=sys.stderr)
        return result.returncode
    if ERROR_PATTERN.search(result.stdout):
        print("FAIL: Godot/runtime error marker found", file=sys.stderr)
        return 1
    if sentinel_count != 1:
        print(f"FAIL: expected one reachable assertion sentinel, found {sentinel_count}", file=sys.stderr)
        return 1
    return 0


def main(argv: list[str]) -> int:
    if len(argv) < 3 or argv[0] != "--sentinel":
        print("usage: run_godot_test.py --sentinel TEXT COMMAND [ARGS...]", file=sys.stderr)
        return 2
    return run(argv[2:], argv[1], float(os.environ.get("GODOT_TEST_TIMEOUT", "30")))


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
