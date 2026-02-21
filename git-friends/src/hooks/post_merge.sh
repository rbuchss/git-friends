#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/task_runner.sh"
source "${BASH_SOURCE[0]%/*/*}/cscope.sh"
source "${BASH_SOURCE[0]%/*/*}/ctags.sh"

function git::hooks::post_merge {
  git::hooks::task_runner 'post-merge' \
    'git::cscope::generate' \
    'git::ctags::generate'
}

function git::hooks::post_merge::__export__ {
  export -f git::hooks::post_merge
}

function git::hooks::post_merge::__recall__ {
  export -fn git::hooks::post_merge
}

git::hooks::post_merge::__export__
