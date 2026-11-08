#!/usr/bin/env python3
"""Check gdam callers against immutable upstream metadata, with mutation controls."""

import copy
import hashlib
import os
import re
import sys
import tomllib
from pathlib import Path
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(Path(os.environ['COOKBOOK_ROOT']) / 'cookbook'))
from mise_entrypoint import read as read_entrypoint
REVISION = "6677226d9353df1d410f3e7f5075e13b3b7d5308"
SOURCE_REVISION = "3a46007e296e60e15a4ad47727ad33046e52e6ea"
DIGESTS = {"publish": "9b9de814668665eb77e34afab9929e9585b1f0047f9c31a8b05706447d27bd10"}


def contracts():
    result = {}
    for action, digest in DIGESTS.items():
        path = ROOT / "tests/fixtures/gdam-actions" / REVISION / action / "action.yml"
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != digest:
            raise ValueError(f"immutable metadata changed: {path}")
        result[f"aviorstudio/gdam-actions/{action}@{SOURCE_REVISION}"] = yaml.safe_load(data)["inputs"]
    return result


def validate(document):
    metadata = contracts()
    seen = set()
    for job in document["jobs"].values():
        for step in job.get("steps", []):
            reference = step.get("uses", "")
            if not reference.startswith("aviorstudio/gdam-actions/"):
                continue
            if reference not in metadata:
                raise ValueError(f"unverified action metadata: {reference}")
            seen.add(reference)
            supplied = step.get("with", {})
            unknown = set(supplied) - set(metadata[reference])
            if unknown:
                raise ValueError(f"{reference}: undeclared inputs {sorted(unknown)}")
            missing = {
                name for name, spec in metadata[reference].items()
                if spec.get("required") and "default" not in spec and name not in supplied
            }
            if supplied.get("api-key") != "${{ secrets.gdam-key || secrets.GDAM_API_KEY }}":
                raise ValueError("missing required inputs: api-key")
            if missing:
                raise ValueError(f"{reference}: missing required inputs {sorted(missing)}")
    if seen != set(metadata):
        raise ValueError("release must exercise the verified gdam publish action")


class ActionInputControls(unittest.TestCase):
    def setUp(self):
        authority = yaml.safe_load((Path(os.environ["COOKBOOK_ROOT"]) / ".github/workflows/cookbook-addon-release.yml").read_text())
        policy = tomllib.loads((ROOT / "cookbook.toml").read_text())["publication"]
        environment_guard = "needs.plan.outputs.environment != ''" if policy.get("environment") else "needs.plan.outputs.environment == ''"
        selected = {name: job for name, job in authority["jobs"].items()
                    if "needs.plan.outputs.registry_auth == 'api-key'" in job.get("if", "")
                    and environment_guard in job.get("if", "")
                    and job.get("permissions", {}).get("id-token") != "write"}
        self.assertEqual(len(selected), 1, "the configured API-key publication branch must have one trusted authority")
        self.workflow = {"jobs": selected}

    def step(self, document, action):
        return next(
            step for job in document["jobs"].values() for step in job.get("steps", [])
            if step.get("uses") == f"aviorstudio/gdam-actions/{action}@{SOURCE_REVISION}"
        )

    def test_caller_uses_the_same_pinned_release_authority(self):
        caller = yaml.safe_load((ROOT / ".github/workflows/release.yml").read_text())
        revision = read_entrypoint(ROOT)['revision']
        release = caller["jobs"]["release"]
        self.assertEqual(release["uses"], f"nicodes/cookbook/.github/workflows/cookbook-addon-release.yml@{revision}")
        self.assertEqual(release["with"]["cookbook-ref"], revision)
        self.assertEqual(release["secrets"]["gdam-key"], "${{ secrets.GDAM_API_KEY }}")
        self.assertEqual(release["permissions"]["contents"], "write")

    def test_actual_release_workflow(self):
        validate(self.workflow)

    def test_publish_version_reinjection_fails_then_restores(self):
        document = copy.deepcopy(self.workflow)
        supplied = self.step(document, "publish")["with"]
        supplied["version"] = "${{ needs.test.outputs.version }}"
        with self.assertRaisesRegex(ValueError, "undeclared inputs.*version"):
            validate(document)
        del supplied["version"]
        validate(document)

    def test_input_typos_fail_then_restore(self):
        for action, typo in (("publish", "tga"),):
            with self.subTest(action=action):
                document = copy.deepcopy(self.workflow)
                supplied = self.step(document, action).setdefault("with", {})
                supplied[typo] = "invalid"
                with self.assertRaisesRegex(ValueError, f"undeclared inputs.*{typo}"):
                    validate(document)
                del supplied[typo]
                validate(document)

    def test_unverified_action_revision_fails(self):
        document = copy.deepcopy(self.workflow)
        self.step(document, "publish")["uses"] = "aviorstudio/gdam-actions/publish@main"
        with self.assertRaisesRegex(ValueError, "unverified action metadata"):
            validate(document)

    def test_required_tag_cannot_disappear(self):
        document = copy.deepcopy(self.workflow)
        del self.step(document, "publish")["with"]["tag"]
        with self.assertRaisesRegex(ValueError, "missing required inputs.*tag"):
            validate(document)


if __name__ == "__main__":
    unittest.main(verbosity=2)
