#!/usr/bin/env bats

load ../test_helper

setup_with_coverage 'git-friends/src/hooks/post_commit.sh'

################################################################################
# git::hooks::post_commit
################################################################################

# bats test_tags=git::hooks::post_commit
@test "git::hooks::post_commit calls task_runner with post-commit" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  # Stub out the task functions so they succeed without external dependencies
  git::cscope::generate() { echo "cscope stub"; }
  export -f git::cscope::generate

  git::ctags::generate() { echo "ctags stub"; }
  export -f git::ctags::generate

  run git::hooks::post_commit
  assert_success
}

# bats test_tags=git::hooks::post_commit
@test "git::hooks::post_commit exits early when disabled" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" config 'git-friends.post-commit.disabled' true
  cd "${repo_dir}"

  run git::hooks::post_commit
  assert_success
}

# bats test_tags=git::hooks::post_commit
@test "git::hooks::post_commit reads skip list from config" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  # Stub out the task functions
  git::cscope::generate() { echo "cscope stub"; }
  export -f git::cscope::generate

  git::ctags::generate() { echo "ctags stub"; }
  export -f git::ctags::generate

  git config 'git-friends.post-commit.skip' 'git::cscope::generate'

  run git::hooks::post_commit
  assert_success
}
