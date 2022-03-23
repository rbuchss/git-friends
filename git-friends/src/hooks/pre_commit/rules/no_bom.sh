#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*/*}/rule.sh"

function file_contains_bom() {
  local file=$1 \
    contents

  read -r -n 3 contents < "${file}"
  [[ "${contents}" == $'\xef\xbb\xbf' ]]
}

function files_do_not_contain_bom() {
  echo "CHECKING files: $@"
}

function git::hooks::pre_commit::rule::commit_has_no_bom() {
  git::hooks::pre_commit::rule \
    --name 'Has No BOM' \
    --fix 'Please remove the BOM(s) and re-add the file(s) for commit' \
    --key 'no-bom' \
    --block 'files_do_not_contain_bom' \
    "$@"
}
