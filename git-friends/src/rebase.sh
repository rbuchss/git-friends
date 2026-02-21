#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/utility.sh"

git::__module__::load || return 0

function git::rebase::to_main {
  local \
    remote="${1:-origin}" \
    main_ref

  if ! main_ref="$(git::utility::get_main_ref "${remote}")"; then
    git::logger::error "Could not find main ref for remote: '${remote}' - exiting"
    return 1
  fi

  git::logger::info "Found git main ref for remote: '${main_ref}' - using to rebase"
  git::exec rebase "${main_ref}"
}

function git::rebase::__export__ {
  export -f git::rebase::to_main
}

function git::rebase::__recall__ {
  export -fn git::rebase::to_main
}

git::__module__::export
