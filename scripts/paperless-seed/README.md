# Paperless-ngx starter taxonomy

`taxonomy.yaml` is the starter structure for `selfhosted/paperless-ngx`: tags, document types, custom fields,
saved views and four workflows. `seed.py` applies it through the Paperless API. Flux does not read either file.

```sh
PAPERLESS_URL=https://docs.<domain> uv run --with pyyaml scripts/paperless-seed/seed.py          # dry run
PAPERLESS_URL=https://docs.<domain> uv run --with pyyaml scripts/paperless-seed/seed.py --apply  # write
```

Credentials come from `PAPERLESS_USER` / `PAPERLESS_PASSWORD`, or the admin login in 1Password item
`paperless-ngx` (vault `Homelab`, desktop app session). The script never prints them.

## Contract

- Objects are matched by name. Missing ones are created. For an existing one, only the fields declared in
  `taxonomy.yaml` are converged.
- Nothing is deleted. Objects made in the UI stay: person tags (kept out of Git on purpose), correspondents
  (the AI workflow creates them) and any extra tags.
- An existing workflow or saved view that differs is reported as `DRIFT` and left alone. To change one, edit
  it in the UI and mirror the change here, or delete it in the UI and re-run `--apply`.
- A custom field's data type cannot change after creation; the script stops instead of trying.

## How the AI workflows behave

| Workflow | Trigger | Does |
|---|---|---|
| New document: inbox + local AI | Document Added (all sources) | adds `inbox`; AI sets title, type, tags (existing only) and created date; AI sets the correspondent (may create one) |
| Reclassify with local AI | Document Updated with tag `ai-classify` | removes `ai-classify`, adds `inbox`, then the same two AI steps |
| Reminders | Scheduled, 60 days before `Valid until` / 7 days before `Due date` | adds `todo` |

- **Reclassify existing documents:** select them in the document list and bulk-add `ai-classify`. Do it in
  batches of about 100. Each document is two `chat-local` requests, and they share the task queue with new
  imports.
- **Why `ai-classify` cannot loop:** it is an inbox tag, and Paperless never offers inbox tags to the AI as
  candidates (`paperless_ai/taxonomy.py`).
- **Review:** everything the AI touches gets `inbox`. Check it, then remove `inbox`. Documents still in the
  inbox are not used to train Paperless' classic matcher.
- AI calls go to the local model through LiteLLM with Paperless' own key (skill `litellm-proxy`). Nothing
  leaves the cluster.
