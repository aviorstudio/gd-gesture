#!/usr/bin/env python3
"""Check GDAM callers against immutable upstream metadata, with mutation controls."""

import copy
import hashlib
from pathlib import Path
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]
REVISION = "d735444eb470194585def44521d5d91df2260e63"
DIGESTS = {
    "install": "1db7bd742af61d8a5ddf6357a2c0f813af623df1dd8b46ed6b32d8f543480d32",
    "publish": "7e7cc2cb3412950c3c5a8f9cfb5f146922a6040da58229ed86f45605700066a5",
}


def contracts():
    result = {}
    for action, digest in DIGESTS.items():
        path = ROOT / "tests/fixtures/gdam-actions" / REVISION / action / "action.yml"
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != digest:
            raise ValueError(f"immutable metadata changed: {path}")
        result[f"aviorstudio/gdam-actions/{action}@{REVISION}"] = yaml.safe_load(data)["inputs"]
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
            if missing:
                raise ValueError(f"{reference}: missing required inputs {sorted(missing)}")
    if seen != set(metadata):
        raise ValueError("release must exercise both verified GDAM actions")


class ActionInputControls(unittest.TestCase):
    def setUp(self):
        self.workflow = yaml.safe_load((ROOT / ".github/workflows/release.yml").read_text())

    def step(self, document, action):
        return next(
            step for job in document["jobs"].values() for step in job.get("steps", [])
            if step.get("uses") == f"aviorstudio/gdam-actions/{action}@{REVISION}"
        )

    def test_actual_release_workflow(self):
        validate(self.workflow)

    def test_install_version_is_declared(self):
        document = copy.deepcopy(self.workflow)
        self.step(document, "install").setdefault("with", {})["version"] = "v0.0.8"
        validate(document)

    def test_publish_version_reinjection_fails_then_restores(self):
        document = copy.deepcopy(self.workflow)
        supplied = self.step(document, "publish")["with"]
        supplied["version"] = "${{ needs.test.outputs.version }}"
        with self.assertRaisesRegex(ValueError, "undeclared inputs.*version"):
            validate(document)
        del supplied["version"]
        validate(document)

    def test_input_typos_fail_then_restore(self):
        for action, typo in (("install", "versoin"), ("publish", "tga")):
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
