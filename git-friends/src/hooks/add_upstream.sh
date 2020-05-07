#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/url.sh"
source "${BASH_SOURCE[0]%/*/*}/utility.sh"

function git::hooks::add_upstream() {
  local upstream_user="$1" \
    origin_url \
    upstream_url

  if [[ -z "${upstream_user}" ]]; then
    read -r -p 'Enter upstream user or organization name: ' upstream_user
  fi

  if [[ -z "${upstream_user}" ]]; then
    >&2 echo 'ERROR: no upstream name provided; so no upstream added'
    return 1
  fi

  if origin_url="$(git config --get remote.origin.url)" \
    && upstream_url="$(git::url::change_user "${origin_url}" "${upstream_user}")" \
    && git::utility::ask "add upstream? ${upstream_url}"; then
      git remote add upstream "${upstream_url}"
  fi
}
