# scripts/ci

Every `*-test.py` here blocks PRs: `ci.yaml` runs them all with one glob step, so a new file needs no
workflow edit. Each needs only python3 and PyYAML, and its docstring says what it prevents.
`version-consistency.sh` and `tofu-validate.sh` run in their own `ci.yaml` jobs.

Run one locally: `python3 scripts/ci/<name>-test.py`; exit 0 means it passed.
