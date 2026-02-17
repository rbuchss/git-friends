#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/exec.sh"
source "${BASH_SOURCE[0]%/*/*}/logger.sh"

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

  git::__exec__ init

  for hook in .git/hooks/*; do
    git::logger::info " - add: '${hook}'"
  done
}

function git::hooks::refresh::__export__ {
  export -f git::hooks::refresh
}

function git::hooks::refresh::__recall__ {
  export -fn git::hooks::refresh
}

git::hooks::refresh::__export__
