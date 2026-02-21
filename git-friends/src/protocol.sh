#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/config.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/url.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/utility.sh"

git::__module__::load || return 0

function git::protocol::set {
  local protocol="$1" \
    name="${2:-origin}" \
    url \
    new_url

  if ! url="$(git::config::get "remote.${name}.url")"; then
    git::logger::error "remote '${name}' not found"
    return 1
  fi

  if new_url="$(git::url::change_protocol "${url}" "${protocol}")" \
    && git::utility::ask "convert remote ${name}: ${url} to ~~~> ${new_url}"; then
    git::exec remote set-url "${name}" "${new_url}"
  fi
}

function git::protocol::__export__ {
  export -f git::protocol::set
}

# KCOV_EXCL_START
function git::protocol::__recall__ {
  export -fn git::protocol::set
}
# KCOV_EXCL_STOP

git::__module__::export
