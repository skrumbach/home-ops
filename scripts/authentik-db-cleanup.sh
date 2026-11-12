#!/usr/bin/env bash
# Authentik DB cleanup: the expired rows clean_expired_models never got through.
#   scripts/authentik-db-cleanup.sh          -> dry run: counts + FK check only (read-only)
#   scripts/authentik-db-cleanup.sh --apply  -> delete expired rows in batches, then VACUUM FULL
# Owner-run (admin kubeconfig).
# Deletes only what upstream clean_expired_models (2026.8.5 authentik/core/tasks.py) deletes:
# django_channels_postgres Message/GroupChannel with expires < now(), expired expiring Sessions, and expired
# ProxySessions (forward-auth outpost sessions).
# Sessions that still have an AuthenticatedSession row are left for the task (Django-side cascade).
# Finally marks a clean_expired_models task stuck in `consumed` as done so the schedule resumes.
set -euo pipefail
export KUBECONFIG=~/.kube/home-ops-admin
APPLY=${1:-}
PRI=$(kubectl -n database get cluster postgres-18 -o jsonpath='{.status.currentPrimary}')
q()  { kubectl -n database exec "$PRI" -c postgres -- psql -d authentik -v ON_ERROR_STOP=1 -At -F ' | ' -c "$1"; }
ro() { kubectl -n database exec "$PRI" -c postgres -- env PGOPTIONS='-c default_transaction_read_only=on' psql -d authentik -v ON_ERROR_STOP=1 -At -F ' | ' -c "$1"; }
sizes() {
  ro "select relname, pg_size_pretty(pg_total_relation_size(relid)) from pg_stat_user_tables
      where relname in ('authentik_core_session','django_channels_postgres_message','django_channels_postgres_groupchannel','authentik_providers_proxy_proxysession')
      order by 1;"
  ro "select 'database', pg_size_pretty(pg_database_size('authentik'));"
}
{
echo "== primary $PRI"
echo "== clean_expired_models task states"
ro "select state, count(*), max(mtime) from authentik_tasks_task
    where actor_name = 'authentik.core.tasks.clean_expired_models' group by 1;"
echo "== foreign keys pointing at authentik_core_session (expect only authentik_core_authenticatedsession)"
FKS=$(ro "select conrelid::regclass from pg_constraint where contype = 'f' and confrelid = 'authentik_core_session'::regclass;")
echo "$FKS"
if [ "$(echo "$FKS" | grep -v -c '^authentik_core_authenticatedsession$' || true)" != "0" ]; then
  echo "ABORT: an unexpected table references authentik_core_session"; exit 1
fi
echo "== foreign keys pointing at authentik_providers_proxy_proxysession (expect none)"
PFK=$(ro "select conrelid::regclass from pg_constraint where contype = 'f' and confrelid = 'authentik_providers_proxy_proxysession'::regclass;")
if [ -n "$PFK" ]; then echo "ABORT: $PFK references authentik_providers_proxy_proxysession"; exit 1; fi
echo "== to delete"
ro "select 'messages', count(*) from django_channels_postgres_message where expires < now();"
ro "select 'groupchannels', count(*) from django_channels_postgres_groupchannel where expires < now();"
ro "select 'anonymous expired sessions', count(*) from authentik_core_session s
    where s.expiring and s.expires < now()
      and not exists (select 1 from authentik_core_authenticatedsession a where a.session_id = s.session_key);"
ro "select 'expired proxy sessions', count(*) from authentik_providers_proxy_proxysession where expiring and expires < now();"
echo "== before"; sizes
if [ "$APPLY" != "--apply" ]; then echo "dry run only; re-run with --apply"; exit 0; fi

echo "== deleting expired messages (batches of 200k)"
while :; do
  n=$(q "with d as (delete from django_channels_postgres_message where ctid in (
           select ctid from django_channels_postgres_message where expires < now() limit 200000) returning 1)
         select count(*) from d;")
  echo "  deleted $n"; [ "$n" -eq 0 ] && break
done
q "delete from django_channels_postgres_groupchannel where expires < now();"
echo "== deleting expired anonymous sessions (batches of 50k)"
while :; do
  n=$(q "with d as (delete from authentik_core_session where session_key in (
           select s.session_key from authentik_core_session s
           where s.expiring and s.expires < now()
             and not exists (select 1 from authentik_core_authenticatedsession a where a.session_id = s.session_key)
           limit 50000) returning 1)
         select count(*) from d;")
  echo "  deleted $n"; [ "$n" -eq 0 ] && break
done
echo "== deleting expired proxy sessions (batches of 50k; ProxySession.expire_action is a plain delete)"
while :; do
  n=$(q "with d as (delete from authentik_providers_proxy_proxysession where uuid in (
           select uuid from authentik_providers_proxy_proxysession
           where expiring and expires < now() limit 50000) returning 1)
         select count(*) from d;")
  echo "  deleted $n"; [ "$n" -eq 0 ] && break
done
echo "== VACUUM FULL (brief exclusive lock per table; Authentik logins pause for seconds)"
for t in django_channels_postgres_message django_channels_postgres_groupchannel authentik_core_session authentik_providers_proxy_proxysession; do
  q "vacuum (full, analyze) $t;"; echo "  $t done"
done
echo "== release stuck clean_expired_models tasks (consumed > 1 day; upstream goauthentik/authentik#18139)"
q "update authentik_tasks_task set state = 'done'
   where actor_name = 'authentik.core.tasks.clean_expired_models' and state = 'consumed'
     and mtime < now() - interval '1 day';"
echo "== after"; sizes
echo "Verify in ~10 min: a fresh clean_expired_models row reaches state done (Admin > System Tasks, or the"
echo "task-states query this script prints first). If not, the schedule itself is stuck."
}
