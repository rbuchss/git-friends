#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/url.sh"
source "${BASH_SOURCE[0]%/*/*}/utility.sh"

function git::hooks::change_protocol() {
  local protocol="$1" \
    remote="${2:-origin}" \
    url \
    new_url

  if ! url="$(git config --get "remote.${remote}.url" 2>/dev/null)"; then
    >&2 echo "ERROR: remote '${remote}' not found"
    return 1
  fi

  if new_url="$(git::url::change_protocol "${url}" "${protocol}")" \
    && git::utility::ask "convert remote ${remote}: ${url} to ~~~> ${new_url}"; then
      git remote set-url "${remote}" "${new_url}"
  fi
}

function git::hooks::change_protocol::to_https() {
  git::hooks::change_protocol 'https' "$@"
}

function git::hooks::change_protocol::to_ssh() {
  git::hooks::change_protocol 'ssh' "$@"
}