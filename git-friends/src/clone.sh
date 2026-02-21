#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/url.sh"

git::__module__::load || return 0

# Clone repository and cd into it.
# Usage: git::clone::cd <repository> [directory] [git-clone-args...]
function git::clone::cd {
  local \
    repository="$1" \
    directory="$2"

  if [[ -z "${repository}" ]]; then
    git::logger::error 'No repository url provided'
    return 1
  fi

  if ! git::exec clone "$@"; then
    return 1
  fi

  # Derive directory if not provided
  if [[ -z "${directory}" ]]; then
    directory="$(git::url::repo_name "${repository}")"
  fi

  git::logger::info "Changing directory to: '${directory}'"
  cd "${directory}" || return 1
}

function git::clone::__export__ {
  export -f git::clone::cd
}

# KCOV_EXCL_START
function git::clone::__recall__ {
  export -fn git::clone::cd
}
# KCOV_EXCL_STOP

git::__module__::export
