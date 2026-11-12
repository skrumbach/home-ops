# OpenCode

Internal coding workspace. Authentik ext-auth on `envoy-internal` only.

LLM calls go to LiteLLM
(`http://litellm.ai.svc.cluster.local:4000/v1`). Default model
`litellm/auto` uses virtual key `litellm-consumer-opencode` and stays
that way. Provider `litellm-projects` is the additional key
`litellm-consumer-litellm-consume-projects`: the Anthropic and OpenAI
chat models on that key's allow-list (not `embedding-local`, not
`jev`). Its $100 per 30 days is one pool shared by every
caller, including Hermes. Never a provider key.

`GITHUB_TOKEN` reuses the `hermes` 1Password item field
`HOMELAB_GH_TOKEN` (`public_repo`, read and write). No new item.

`OPENCODE_PASSWORD` is 1Password item `opencode` (vault `Homelab`),
the server password (user `opencode`). Without it each start makes a
random one and logs it; rotating it signs out every session.

Namespace `ai` is already on the Authentik ReferenceGrant. A new
hostname still needs a real login after merge before treating the route
as covered. Do not add a second
basic-auth API route.
