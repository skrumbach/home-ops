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

# Hindsight memory plugin, loaded through `plugin` in opencode.json. The image has no node or npm and the
# package has no dependencies, so the pinned tarball is unpacked onto the home PVC once per version.
# Bump the version and the sha512 together (hex of the npm tarball: `shasum -a 512`).
# A failed download keeps the copy already on the PVC.
plugin_dir="${HOME}/.local/share/hindsight-coding-agents"
plugin_version=0.8.8
plugin_sha512=36a1caeb8cfd801adb94ea5a55268078768b41cc4f0a9ef08a563a5f833a93806f8113b957050d63f70c4c966dd02d1d264a84965358dcde80d9fc72ded95f36
if [[ "$(cat "${plugin_dir}/.version" 2>/dev/null || true)" != "${plugin_version}" ]]; then
  plugin_tmp="$(mktemp -d)"
  if curl -fsSL -o "${plugin_tmp}/plugin.tgz" \
      "https://registry.npmjs.org/@vectorize-io/hindsight-coding-agents/-/hindsight-coding-agents-${plugin_version}.tgz" \
    && echo "${plugin_sha512}  ${plugin_tmp}/plugin.tgz" | sha512sum -c - >/dev/null; then
    rm -rf "${plugin_dir}"
    mkdir -p "${plugin_dir}"
    tar -xzf "${plugin_tmp}/plugin.tgz" -C "${plugin_dir}" --strip-components=1
    echo "${plugin_version}" > "${plugin_dir}/.version"
  else
    echo "WARN: hindsight plugin ${plugin_version} download or checksum failed; memory stays on the previous copy, if any"
  fi
  rm -rf "${plugin_tmp}"
fi

mkdir -p "${HOME}/projects"
if [[ ! -d "${HOME}/projects/home-ops/.git" ]]; then
  git clone --filter=blob:none https://github.com/skrumbach/home-ops.git "${HOME}/projects/home-ops" \
    || echo "WARN: home-ops clone failed; clone it from a session instead"
fi

cd "${HOME}/projects"
exec opencode serve --hostname 0.0.0.0 --port 4096
