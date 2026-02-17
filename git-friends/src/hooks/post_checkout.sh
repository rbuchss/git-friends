#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/task_runner.sh"
source "${BASH_SOURCE[0]%/*/*}/cscope.sh"
source "${BASH_SOURCE[0]%/*/*}/ctags.sh"

function git::hooks::post_checkout {
  git::hooks::task_runner 'post-checkout' \
    'git::cscope::generate' \
    'git::ctags::generate'
}

function git::hooks::post_checkout::__export__ {
  export -f git::hooks::post_checkout
}

function git::hooks::post_checkout::__recall__ {
  export -fn git::hooks::post_checkout
}

git::hooks::post_checkout::__export__
