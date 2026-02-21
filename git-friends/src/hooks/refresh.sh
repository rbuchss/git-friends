#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*/*}}/logger.sh"

git::__module__::load || return 0

function git::hooks::refresh {
  local hooks=(.git/hooks/*)

  if (("${#hooks[@]}" != 0)); then
    git::logger::info 'Clearing out old hooks:'

    for hook in "${hooks[@]}"; do
      git::logger::info " - remove: '${hook}'"
      rm -r "${hook}" || {
        git::logger::error "failed: cannot remove '${hook}'"
        return 1
      }
    done
  fi

  git::logger::info 'Loading current hooks:'

  git::exec init

  for hook in .git/hooks/*; do
    git::logger::info " - add: '${hook}'"
  done
}

function git::hooks::refresh::__export__ {
  export -f git::hooks::refresh
}

# KCOV_EXCL_START
function git::hooks::refresh::__recall__ {
  export -fn git::hooks::refresh
}
# KCOV_EXCL_STOP

git::__module__::export
