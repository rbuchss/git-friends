#!/usr/bin/env bats

load ../test_helper

setup_with_coverage 'git-friends/src/hooks/post_rewrite.sh'

################################################################################
# git::hooks::post_rewrite
################################################################################

# bats test_tags=git::hooks::post_rewrite
@test "git::hooks::post_rewrite runs task_runner for rebase" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  # Stub out the task functions so they succeed without external dependencies
  git::cscope::generate() { echo "cscope stub"; }
  export -f git::cscope::generate

  git::ctags::generate() { echo "ctags stub"; }
  export -f git::ctags::generate

  run git::hooks::post_rewrite 'rebase'
  assert_success
}

# bats test_tags=git::hooks::post_rewrite
@test "git::hooks::post_rewrite does nothing for amend" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::hooks::post_rewrite 'amend'
  assert_success
  refute_output
}

# bats test_tags=git::hooks::post_rewrite
@test "git::hooks::post_rewrite does nothing for unknown action" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::hooks::post_rewrite 'unknown-action'
  assert_success
  refute_output
}

# bats test_tags=git::hooks::post_rewrite
@test "git::hooks::post_rewrite does nothing with no arguments" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::hooks::post_rewrite
  assert_success
  refute_output
}

# bats test_tags=git::hooks::post_rewrite
@test "git::hooks::post_rewrite exits early when disabled for rebase" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" config 'git-friends.post-rewrite.disabled' true
  cd "${repo_dir}"

  # Stub out the task functions
  git::cscope::generate() { echo "cscope stub"; }
  export -f git::cscope::generate

  git::ctags::generate() { echo "ctags stub"; }
  export -f git::ctags::generate

  run git::hooks::post_rewrite 'rebase'
  assert_success
}

# bats test_tags=git::hooks::post_rewrite
@test "git::hooks::post_rewrite reads skip list from config for rebase" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  # Stub out the task functions
  git::cscope::generate() { echo "cscope stub"; }
  export -f git::cscope::generate

  git::ctags::generate() { echo "ctags stub"; }
  export -f git::ctags::generate

  git config 'git-friends.post-rewrite.skip' 'git::cscope::generate'

  run git::hooks::post_rewrite 'rebase'
  assert_success
}
