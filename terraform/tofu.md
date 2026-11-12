# OpenTofu in this repo

OpenTofu manages configuration that lives in an application's own API.
Flux does not reconcile this tree. Stacks:
[`authentik/`](./authentik) (SSO),
[`unifi/`](./unifi) (the UDM Pro SE) and
[`truenas/`](./truenas) (the NAS).

1. Nothing here applies itself. `terraform-diff.yaml` may post a read-only
   plan. `tofu apply` stays behind an explicit, current go-ahead.
2. State never goes in Git. Authentik's holds OAuth client secrets and lives
   in a private RGW bucket; UniFi's and TrueNAS's are encrypted in R2,
   outside the cluster.
3. Adopt objects that already exist (`import` blocks). Create only what
   never lived on the instance (LiteLLM).
4. Secrets come from 1Password through `vals exec -i`. No committed tfvars.

```bash
cd terraform/<stack>
vals exec -i -f secrets.vals.yaml -- tofu plan
./scripts/ci/tofu-validate.sh
```

Never `tofu destroy` a stack. Authentik's unbinds ExtAuth; UniFi's deletes
the networks the cluster runs on; TrueNAS's tries to delete shares and data.
