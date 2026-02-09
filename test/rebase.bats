#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/rebase.sh'

# Helper to create a cloned repo on a feature branch.
# Sets repo_dir in caller's scope.
__create_feature_branch_repo() {
  local source_dir="${BATS_TEST_TMPDIR}/source"

  repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"
  git -C "${repo_dir}" checkout -b 'feature'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'feature commit'
}

################################################################################
# git::rebase::to_main
################################################################################

# bats test_tags=git::rebase::to_main
@test "git::rebase::to_main rebases current branch onto main ref" {
  local repo_dir

  __create_feature_branch_repo
  cd "${repo_dir}"

  run git::rebase::to_main
  assert_success
}

# bats test_tags=git::rebase::to_main
@test "git::rebase::to_main fails when no main ref found" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" checkout -b 'unrelated'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  cd "${repo_dir}"

  run git::rebase::to_main
  assert_failure
}
