#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/url.sh"
source "${BASH_SOURCE[0]%/*}/utility.sh"

function git::upstream::add() {
  local user="$1" \
    name="${2:-upstream}" \
    origin_url \
    upstream_url

  if [[ -z "${user}" ]]; then
    read -r -p 'Enter upstream user or organization name: ' user
  fi

  if [[ -z "${user}" ]]; then
    >&2 echo 'ERROR: no upstream user/organization name provided'
    return 1
  fi

  if origin_url="$(git config --get remote.origin.url)" \
    && upstream_url="$(git::url::change_user "${origin_url}" "${user}")" \
    && git::utility::ask "add remote '${name}':  ${upstream_url}"; then
      git remote add "${name}" "${upstream_url}"
  fi
}
