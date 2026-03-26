#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"

git::__module__::load || return 0

# Git credential helper for token-based authentication.
# Called by git with action as first argument: get, store, or erase.
# Reads GITHUB_TOKEN (or GIT_FRIENDS_CREDENTIAL_TOKEN) from the environment.
#
# Configure via git config:
#   credential.https://github.com.helper = /path/to/credential-helper
#
# Or inject via environment:
#   GIT_CONFIG_COUNT=1
#   GIT_CONFIG_KEY_0=credential.https://github.com.helper
#   GIT_CONFIG_VALUE_0=/path/to/credential-helper
function git::credential::token_helper {
  local action="$1"
  local line

  # Consume stdin per git credential helper protocol
  while IFS= read -r line && [[ -n "${line}" ]]; do :; done

  # Only respond to 'get' requests; ignore 'store' and 'erase'
  if [[ "${action}" != "get" ]]; then
    return 0
  fi

  local token="${GITHUB_TOKEN:-${GIT_FRIENDS_CREDENTIAL_TOKEN:-}}"

  if [[ -z "${token}" ]]; then
    return 1
  fi

  local username="${GIT_FRIENDS_CREDENTIAL_USERNAME:-x-access-token}"

  printf "username=%s\n" "${username}"
  printf "password=%s\n" "${token}"
}

function git::credential::__export__ {
  export -f git::credential::token_helper
}

# KCOV_EXCL_START
function git::credential::__recall__ {
  export -fn git::credential::token_helper
}
# KCOV_EXCL_STOP

git::__module__::export
