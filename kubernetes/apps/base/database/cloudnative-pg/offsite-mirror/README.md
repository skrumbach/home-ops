# postgres-18 off-site archive mirror

> **This mirror is LIVE** (`suspend: false`, owner decision D1). Setting `suspend: true`
> again turns the off-site copy off; `PostgresOffsiteMirrorStale` then fires within 6h.
> It needs the `cloudflare-r2` 1Password item and the R2 bucket (see [Credential](#credential));
> without them every run sits in `CreateContainerConfigError` or fails with a 403.

Copies the `postgres-18` barman archive from the LAN TrueNAS MinIO (not Ceph RGW) to
Cloudflare R2, so the cluster's only Postgres backup copy stops being a single LAN target.
Every one of the fleet's file volumes already has both a Ceph copy and an off-site copy;
Postgres was the outlier.

Why a mirror and not a second destination is below.

## Why a mirror and not a second CNPG destination

CloudNativePG has exactly **one** live barman destination per `Cluster`, and the mechanism
that looks like it lifts that limit is silently broken:

- `spec.backup.barmanObjectStore` is a single object, not a list.
- The live CRD states `isWALArchiver` "cannot be enabled if the
  `.spec.backup.barmanObjectStore` configuration is present", so WAL archiving is
  single-destination regardless of the plugin.
- `plugin-barman-cloud` (v0.15.0 and `main`) resolves the destination **only** from the
  Cluster's `spec.plugins`. A `ScheduledBackup` carrying its own `barmanObjectName` is
  accepted and ignored - it reports `completed` while writing to the LAN store
  ([cloudnative-pg#7778](https://github.com/cloudnative-pg/cloudnative-pg/issues/7778),
  closed as not planned).
- `barman-cloud-backup` bundles no WAL, so a base backup in a store that receives no WAL
  cannot reach consistency on restore even if the above were fixed.

Copying the archive itself moves `base/` **and** `wals/` together, which is what makes the
off-site copy independently restorable, and it changes nothing on the live `Cluster` - no
plugin, no `spec.plugins`, no rolling restart of the three Postgres instances.

## The three rules that are correctness, not tuning

**Copy-only.** `rclone copy` never deletes on the destination. It must never become
`rclone sync`, and no `--delete-*` flag may be added. CNPG enforces its 30d window by
running `barman-cloud-backup-delete` against the LAN store; propagating those deletions
would make the 35d off-site window fiction (objects would go at 30d, before the prune
could apply) and would carry any LAN-side wipe straight to the off-site copy. A copy that
faithfully reproduces the loss it exists to survive is a replica, not a backup.

**No base backup, no run.** A wiped or mis-pointed source is listable and empty, so
`rclone copy` copies nothing and exits 0 (measured). The prune would then empty R2 over
35d while every run reported success. The job therefore fails before copying when the
source has no `base/*/backup.info`. A fresh `serverName` gets its first base backup at
creation (`ScheduledBackup` `immediate: true`), so this is at most one failed run.

**Expiry is independent.** The 35d prune is an age-based rule applied to the destination,
never a reflection of what the LAN deleted. It runs only after a successful copy (`set -eu`),
ages objects by their R2 upload time (`--use-server-modtime`), and refuses to act when the
candidate count exceeds `PRUNE_CEILING`. Upload time is never earlier than the LAN write, so
every object stays at least 35d in R2, a seed of old objects is not pruned on arrival, an
R2 bucket lock shorter than 35d never blocks the prune, and no per-object `HEAD` is needed.

`scripts/ci/postgres-offsite-mirror-test.py` pins `SERVER_NAME` against the live archiver:
a restore that bumps the Cluster's `serverName` must bump this CronJob in the same commit,
or the mirror keeps copying the old path and succeeding.

## Storage and cost

R2 holds about 35d of the archive: LAN's 30d recovery window plus 5d, roughly 360 WAL
segments a day plus the daily bzip2 base backups. Growth is bounded by the prune, not by
the LAN. Plain copy with no prune would grow without bound; `sync` would be bounded but
mirrors every deletion and wipe. Each hourly run lists both sides (R2 Class B operations)
and compares by size only (`--size-only`: barman objects are write-once), so it makes no
per-object `HEAD`. The source guard lists only `base/`, never the WAL stream.

**A `serverName` bump strands the old R2 prefix.** The copy and the prune cover
`SERVER_NAME` only. Once the mirror moves to `postgres18-v3`, nothing ever expires
`postgres18-v2/` in R2. Delete it by hand once the new archive has its own 35d of history.

## Reading the off-site recovery point

A half-written WAL object **cannot** be copied - an in-flight `PutObject` is neither
listable nor gettable, and a multipart upload becomes an object only at
`CompleteMultipartUpload`. The residual risk is an incomplete *set*: a base backup whose
trailing `backup.info` has not landed (inert, since barman's catalogue keys off that file),
or a WAL gap from an interrupted run.

So the off-site recovery point is **the last contiguous WAL segment**, not the newest
object present. PITR needs an unbroken chain.

## Credential

| | |
|---|---|
| 1Password item | `cloudflare-r2` |
| Vault | `Homelab` (the `onepassword` ClusterSecretStore reads `Homelab`, then `Automation`, then `Services`; **never** the hyphenated `Home-Lab`, which Connect cannot see at all) |
| Fields | `R2_K8S_ENDPOINT_URL` (`https://<account-id>.r2.cloudflarestorage.com`, no bucket in the path), `R2_K8S_ACCESS_KEY_ID`, `R2_K8S_SECRET_ACCESS_KEY` (mapped to the unprefixed keys in `cloudnative-pg-r2-secret`) |
| R2 bucket | `home-ops-postgres-cluster` (same name as the LAN bucket, on purpose; the name is in git, not the item) |
| R2 API token | Account API token, **Object Read & Write**, applied to bucket `home-ops-postgres-cluster` only |

The endpoint lives in the item rather than in git because it embeds the Cloudflare account
id, the same reason `system/kopiur` keeps it there. The token needs object read/write on
that bucket only - `--s3-no-check-bucket` means no `HeadBucket`/`CreateBucket` call is made,
so the bucket must be created in the dashboard first.

Neither existing R2 token is reused: `kopiur-r2` is scoped to bucket `kopiur` alone
(`volsync` 403s, `ListBuckets` denied) and `volsync-template`'s `R2_HOME_OPS_*` is scoped
to `volsync`.

**Bucket lock (recommended): one rule, whole bucket, retention 30 days.** R2 has no S3
object versioning; a bucket lock is its immutability control. It stops a leaked token or a
broken script from deleting or overwriting any object younger than 30d. It never collides
with the 35d prune, which ages by upload time. Barman objects are write-once, so the
lock costs nothing extra.

Fields are fetched by explicit `data` + `property`, so a missing field fails the
`ExternalSecret` loudly. An empty field does not: `SecretSynced` is reported with a
zero-length value, so check key lengths, not the status.

## Alerting

`PostgresOffsiteMirrorStale` (`prometheusrule.yaml`, warning) fires when the CronJob has no
successful run in 6h, or has never succeeded 2h after the rule loads (`absent()`). Each
failed Job also raises the fleet `KubeJobFailed`. Both arms were evaluated against live
Prometheus before merge: the `absent()` arm returns the never-run mirror, and the age arm
returns a series for a CronJob more than 4h stale and none for a fresh one.

## Known follow-ups

- **The restore path remains unproven.** No CNPG restore has ever been exercised on this
  cluster; all restore runbooks (`.agents/skills/incident-runbooks/references/restore.md`) are kopiur or retired VolSync. The drill was
  deliberately deferred by the captain on 2026-09-11 and is out of scope here.
