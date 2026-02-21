#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/exec.sh"
source "${BASH_SOURCE[0]%/*}/logger.sh"
source "${BASH_SOURCE[0]%/*}/utility.sh"

function git::submodule::remove {
  local submodule_path
  # shellcheck disable=SC2034
  local all_response

  for submodule_path in "$@"; do
    if [[ ! -d "${submodule_path}" ]]; then
      git::logger::error "path to submodule: '${submodule_path}' not found"
      return 1
    fi

    if git::utility::ask "remove submodule? ${submodule_path}" all_response; then
      # 1: Remove the submodule entry from .git/config
      # 2: Remove the submodule directory from the superproject's .git/modules directory
      # 3: Remove the entry in .gitmodules and remove the submodule directory located at ${submodule_path}
      git::__exec__ submodule deinit -f -- "${submodule_path}" \
        && rm -rf ".git/modules/${submodule_path}" \
        && git::__exec__ rm -f "${submodule_path}"
    fi
  done
}

function git::submodule::sync {
  if (($# > 0)); then
    git::__exec__ submodule update --init --recursive -- "$@"
    return
  fi

  git::__exec__ submodule update --init --recursive
}

function git::submodule::upgrade {
  # NOTE: old way: git submodule foreach git pull origin master
  if (($# > 0)); then
    git::__exec__ submodule update --recursive --remote -- "$@"
    return
  fi

  git::__exec__ submodule update --recursive --remote
}

function git::submodule::__export__ {
  export -f git::submodule::remove
  export -f git::submodule::sync
  export -f git::submodule::upgrade
}

function git::submodule::__recall__ {
  export -fn git::submodule::remove
  export -fn git::submodule::sync
  export -fn git::submodule::upgrade
}

git::submodule::__export__
