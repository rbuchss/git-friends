#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"

git::__module__::load || return 0

function git::cd::root_dir {
  local root_dir

  if ! root_dir="$(git::exec rev-parse --show-toplevel)"; then
    return 1
  fi

  git::logger::info "Changing directory to root: '${root_dir}'"

  cd "${root_dir}" || return 1
}

function git::cd::__export__ {
  export -f git::cd::root_dir
}

function git::cd::__recall__ {
  export -fn git::cd::root_dir
}

git::__module__::export
