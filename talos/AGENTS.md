# Talos

Planned power-down and power-on: `.agents/skills/incident-runbooks/references/power-down-up.md`.

`talosctl validate` is a schema check. It does not catch a bad enum, a bad CIDR, or a missing install disk. Green validate is not permission to `apply-node`.

`just bootstrap cluster` is disaster recovery only. See `bootstrap/README.md`.
