# scripts/docs

`build.py` writes the documentation site's content tree from the repository, so every merge
documents itself and no page is maintained by hand. The Hugo theme in `docs/` renders it.

Reads:

- the cluster as `flate build all --path kubernetes/clusters/main -o json` renders it
  (run through `mise exec --` when `flate` is not on PATH; Secrets and CRDs are skipped);
- the overlay files `kubernetes/apps/main/<ns>/<app>.yaml`: one file is one app, and its Flux
  Kustomizations give the paths, `dependsOn`, components and substitutions;
- `.renovaterc.json5` and `.renovate/*.json5`;
- a fixed list of hand-written Markdown (`OPS_ORDER`, `OPS_REST`, the runbooks, `terraform/`), plus every
  `README.md`/runbook under `kubernetes/apps/base/<ns>/<app>/` (shown on that app's page) and
  `kubernetes/apps/base/<ns>/README.md` (shown on the namespace page).

Writes `docs/.build/content/` (deleted and recreated every run, gitignored): `apps/`, `reference/`,
`operations/` and the home page, Markdown with front matter only. The same commit always gives the
same bytes: everything is sorted and the only date is the commit date.

The site is public. The script publishes names only: no Secret data, no ExternalSecret templates,
no env values, no ConfigMap contents.

Run:

```bash
uv run --script scripts/docs/build.py                      # renders with flate, a few seconds once cached
uv run --script scripts/docs/build.py --rendered FILE      # reuse a render (JSON or YAML)
task docs:serve                                            # build, then hugo server
```

Flags: `--out DIR`, `--repo OWNER/NAME` (default `$GITHUB_REPOSITORY`, then `origin`), `--branch main`.

Add a hand-written page: put the Markdown next to what it describes. Under
`kubernetes/apps/base/<ns>/<app>/` it lands on that app's page with no change here; anywhere else,
add its path to `OPS_REST` in `build.py`. The first `# ` heading becomes the title, and relative links
are rewritten to site pages or GitHub.
