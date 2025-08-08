#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/config.sh"
source "${BASH_SOURCE[0]%/*}/url.sh"
source "${BASH_SOURCE[0]%/*}/utility.sh"

function git::protocol::set {
  local protocol="$1" \
    name="${2:-origin}" \
    url \
    new_url

  if ! url="$(git::config::get "remote.${name}.url")"; then
    >&2 echo "ERROR: remote '${name}' not found"
    return 1
  fi

  if new_url="$(git::url::change_protocol "${url}" "${protocol}")" \
    && git::utility::ask "convert remote ${name}: ${url} to ~~~> ${new_url}"; then
      git remote set-url "${name}" "${new_url}"
  fi
}
