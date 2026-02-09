#!/usr/bin/env bats

load ../test_helper

setup_with_coverage 'git-friends/src/hooks/post_merge.sh'

################################################################################
# git::hooks::post_merge
################################################################################

# bats test_tags=git::hooks::post_merge
@test "git::hooks::post_merge calls task_runner with post-merge" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  # Stub out the task functions so they succeed without external dependencies
  git::cscope::generate() { echo "cscope stub"; }
  export -f git::cscope::generate

  git::ctags::generate() { echo "ctags stub"; }
  export -f git::ctags::generate

  run git::hooks::post_merge
  assert_success
}

# bats test_tags=git::hooks::post_merge
@test "git::hooks::post_merge exits early when disabled" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" config 'git-friends.post-merge.disabled' true
  cd "${repo_dir}"

  run git::hooks::post_merge
  assert_success
}

# bats test_tags=git::hooks::post_merge
@test "git::hooks::post_merge reads skip list from config" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  # Stub out the task functions
  git::cscope::generate() { echo "cscope stub"; }
  export -f git::cscope::generate

  git::ctags::generate() { echo "ctags stub"; }
  export -f git::ctags::generate

  git config 'git-friends.post-merge.skip' 'git::cscope::generate'

  run git::hooks::post_merge
  assert_success
}
