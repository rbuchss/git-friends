#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/exec.sh"
source "${BASH_SOURCE[0]%/*}/logger.sh"
source "${BASH_SOURCE[0]%/*}/url.sh"
source "${BASH_SOURCE[0]%/*}/utility.sh"

function git::upstream::add {
  local user="$1" \
    name="${2:-upstream}" \
    origin_url \
    upstream_url

  if [[ -z "${user}" ]]; then
    read -r -p 'Enter upstream user or organization name: ' user
  fi

  if [[ -z "${user}" ]]; then
    git::logger::error 'no upstream user/organization name provided'
    return 1
  fi

  if origin_url="$(git::__exec__ config --get remote.origin.url)" \
    && upstream_url="$(git::url::change_user "${origin_url}" "${user}")" \
    && git::utility::ask "add remote '${name}':  ${upstream_url}"; then
    git::__exec__ remote add "${name}" "${upstream_url}"
  fi
}

function git::upstream::__export__ {
  export -f git::upstream::add
}

function git::upstream::__recall__ {
  export -fn git::upstream::add
}

git::upstream::__export__
