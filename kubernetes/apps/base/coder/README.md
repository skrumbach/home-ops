# Coder

Workspace platform. Sign in with Pocket ID; do not create a local password user.

Password auth is disabled (`CODER_DISABLE_PASSWORD_AUTH=true`). Only members of
the Pocket ID group `admins` can sign in (`CODER_OIDC_ALLOWED_GROUPS` and the
client's `allowedUserGroups`). The group and role mappings in
`app/helmrelease.yaml` need a Coder Premium license, which this deployment does
not have: a user keeps whatever roles it has in Coder, no group grants `owner`.
There is no first-boot admin-user form to fill, and you should not `UPDATE`
`users.rbac_roles` in Postgres to grant admin.

If a first-connect setup wizard still appears, it is leftover Coder chart UI.
Skip it and use **Sign in with Pocket ID**.

OIDC issuer: `https://id.sklab.dev` (see `app/helmrelease.yaml`); client in
`app/pocketidoidcclient.yaml`. On start Coder clears the link of every OIDC user
bound to a different issuer, and the next login re-links that user by email, so
the Pocket ID email must equal the Coder user's email.

## Break-glass for an issuer change

1. Before the cutover, mint a token: `coder tokens create --name pocket-id-cutover --lifetime 168h`.
   A token session is never refreshed through the identity provider, so it keeps
   working whatever the provider does. Remove it afterwards (`coder tokens remove pocket-id-cutover`).
2. Do not sign in while the rollout is in progress: the old pod still serves the old
   issuer, and a login there re-binds the cleared link to it.
3. A 403 "Account already linked" means the startup reset did not run. Restart the
   pod (it runs on every start). Only if the log says the issuer could not be resolved,
   run `kubectl -n coder exec -it deploy/coder -- /opt/coder server fix-oidc-links --issuer-url <issuer>`.
4. A `git revert` of the cutover commit is a full rollback while the old client still
   exists: on start Coder clears the new links and the next login re-links by email.
5. Password login is refused for every user, owners included, while
   `CODER_DISABLE_PASSWORD_AUTH` is true. Last resort: `kubectl -n coder exec -it deploy/coder --
   /opt/coder server create-admin-user` (writes an owner with a password straight to the
   database) plus a commit setting `CODER_DISABLE_PASSWORD_AUTH` to `"false"` (a restart);
   revert the commit and delete that user afterwards.
