#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/task_runner.sh"
source "${BASH_SOURCE[0]%/*/*}/cscope.sh"
source "${BASH_SOURCE[0]%/*/*}/ctags.sh"

function git::hooks::post_commit {
  git::hooks::task_runner 'post-commit' \
    'git::cscope::generate' \
    'git::ctags::generate'
}
