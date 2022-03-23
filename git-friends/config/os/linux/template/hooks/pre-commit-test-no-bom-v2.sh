#!/bin/bash
# shellcheck source=/dev/null
source "${HOME}/.git-friends/src/hooks/pre_commit/rules/no_bom.sh"

git::hooks::pre_commit::rule::commit_has_no_bom "$@"
