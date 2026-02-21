#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/exec.sh"
source "${BASH_SOURCE[0]%/*}/logger.sh"

function git::cd::root_dir {
  local root_dir

  if ! root_dir="$(git::__exec__ rev-parse --show-toplevel)"; then
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

git::cd::__export__
