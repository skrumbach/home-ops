#!/bin/bash
set -euo pipefail

git config --global user.name "Sascha Krumbach"
git config --global user.email "sascha.s.krumbach@gmail.com"
git config --global init.defaultBranch main
git config --global --add safe.directory '*'

# GITHUB_TOKEN is optional: home-ops is public, so an anonymous clone works
# without it. When set (see this app's README.md), it also enables push.
# The token is read from the environment by a credential helper on every use,
# so it is never written to the home PVC (kopia snapshots). Earlier revisions
# wrote it to ~/.git-credentials; remove that file so the old copy stops
# being read. Old snapshots still contain it: rotating the token is an owner task.
rm -f "${HOME}/.git-credentials"
# shellcheck disable=SC2016 # single quotes on purpose: $1 and $GITHUB_TOKEN expand when git runs the helper
git config --global --replace-all credential.helper '!f() { test "$1" = get && test -n "$GITHUB_TOKEN" && printf "username=x-access-token\npassword=%s\n" "$GITHUB_TOKEN"; }; f'

mkdir -p "${HOME}/projects"
if [[ ! -d "${HOME}/projects/home-ops/.git" ]]; then
  git clone --filter=blob:none https://github.com/skrumbach/home-ops.git "${HOME}/projects/home-ops" \
    || echo "WARN: home-ops clone failed; clone it from a session instead"
fi

cd "${HOME}/projects"
exec opencode serve --hostname 0.0.0.0 --port 4096
