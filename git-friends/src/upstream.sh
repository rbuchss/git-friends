#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/url.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/utility.sh"

git::__module__::load || return 0

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

  if origin_url="$(git::exec config --get remote.origin.url)" \
    && upstream_url="$(git::url::change_user "${origin_url}" "${user}")" \
    && git::utility::ask "add remote '${name}':  ${upstream_url}"; then
    git::exec remote add "${name}" "${upstream_url}"
  fi
}

function git::upstream::__export__ {
  export -f git::upstream::add
}

# KCOV_EXCL_START
function git::upstream::__recall__ {
  export -fn git::upstream::add
}
# KCOV_EXCL_STOP

git::__module__::export
