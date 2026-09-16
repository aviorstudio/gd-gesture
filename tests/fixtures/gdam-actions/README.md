# Immutable GDAM action contracts

`d735444eb470194585def44521d5d91df2260e63/{install,publish}/action.yml`
are verbatim upstream metadata from `aviorstudio/gdam-actions` v0.0.2:

- https://github.com/aviorstudio/gdam-actions/blob/d735444eb470194585def44521d5d91df2260e63/install/action.yml
- https://github.com/aviorstudio/gdam-actions/blob/d735444eb470194585def44521d5d91df2260e63/publish/action.yml

`tools/test_action_inputs.py` verifies their SHA-256 before parsing and checks
actual release callers, unknown revisions, required inputs, unsupported publish
`version` reinjection, input typos, and restored controls. Install `version` is a
valid input; publish takes exact `tag`, not a separate version. A future action
upgrade must update these fixtures and recorded digests from that immutable
upstream revision, not edit the copied contract to accommodate callers.

The CI and Release shared test action runs this test with PyYAML 6.0.2 in an
isolated virtual environment. Locally, install `PyYAML==6.0.2` into a virtual
environment and run `python tools/test_action_inputs.py` from the repository.
