# Authentik database bloat

Alert `AuthentikDatabaseBloated` (`kubernetes/apps/base/security/authentik/app/prometheusrule.yaml`)
fires when the `authentik` database on `postgres-18` stays over 2 GiB for 6h. Live data is a few
hundred MB.

## Cause

`clean_expired_models` (every 5 min, `authentik/core/tasks.py`) deletes expired `Session` rows and
`django_channels_postgres` `Message`/`GroupChannel` rows one object at a time, under the 10 minute
`AUTHENTIK_WORKER__TASK_DEFAULT_TIME_LIMIT`. Once the backlog outgrows one run it never catches up.
Measured 2026-11-08 on 2026.8.5: 6.26 GB, of which 1,028,216 expired sessions (3.1 GB) and
9,549,995 expired messages to dead `asgi.specific.*` channels (2.6 GB), all expired since
2026-05-27. Events are not the cause (about 1,500 rows). The bloat rides into every daily base
backup and the 35 day R2 archive mirror (skill `databases`).

`pg_stat_user_tables` row counts are unreliable here (they read ~19k messages); count the table.

## Fix

Owner-run, admin kubeconfig. `scripts/authentik-db-cleanup.sh` dry-runs by default: it prints the
task states, refuses if anything other than `authentik_core_authenticatedsession` has a foreign key
to `authentik_core_session`, and counts what it would delete. `--apply` deletes in batches
exactly the rows the task targets, except sessions that still have an `AuthenticatedSession`
(left to the task, whose Django-side cascade handles them), then `VACUUM (FULL, ANALYZE)` on the
three tables. Each `VACUUM FULL` takes an exclusive lock for seconds; logins pause meanwhile.
A plain `DELETE` without `VACUUM FULL` frees no disk and does not shrink the base backups.

The R2 mirror shrinks only as the 35 day prune ages out the bloated base backups.
