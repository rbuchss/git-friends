#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.git-friends/src/cd.sh"

# NOTE: this needs to be a bash alias vs a git one since git aliases run
# in a subshell and as such cannot change the the parent shell's directory.
alias gcd='git::cd::root_dir'
