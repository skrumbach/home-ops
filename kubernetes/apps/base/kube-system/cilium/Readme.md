# Cilium

Chart pin, BGP CRs and LoadBalancer pool:
`app/ocirepository.yaml`, `app/networking.yaml`.

UniFi is not reconciled from here. The UDM's FRR config is
`terraform/unifi/bgp.conf` (OpenTofu); change it together with `app/networking.yaml`.

Host firewall policy: `app/hostpolicy-ceph.yaml`.

Hubble: agent server, relay and UI are on, with flow metrics (dns, drop,
tcp, flow, port-distribution, icmp, httpV2) scraped by ServiceMonitors and
dashboards in the Grafana `Cilium` folder. The UI is
`hubble.${SECRET_DOMAIN}` on `envoy-internal` behind Authentik ExtAuth
(`app/httproute.yaml`, `app/securitypolicy.yaml`). Certs use
`hubble.tls.auto.method: cronJob`: the chart's `helm` method reuses its leaf
certs on every upgrade and never renews them, while certgen renews every four
months and keeps the Secrets out of the release, so no `driftDetection`
ignore is needed.
