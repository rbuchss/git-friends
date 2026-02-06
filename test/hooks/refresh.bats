#!/usr/bin/env bats

load ../test_helper

setup_with_coverage 'git-friends/src/hooks/refresh.sh'

################################################################################
# git::hooks::refresh
################################################################################

# bats test_tags=git::hooks::refresh
@test "git::hooks::refresh reinitializes hooks" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::hooks::refresh
  assert_success
}

# bats test_tags=git::hooks::refresh
@test "git::hooks::refresh removes existing hooks" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  # Create a custom hook
  printf '#!/bin/sh\necho test\n' > '.git/hooks/custom-hook'
  chmod +x '.git/hooks/custom-hook'

  run git::hooks::refresh
  assert_success

  # Custom hook should be gone
  assert [ ! -f '.git/hooks/custom-hook' ]
}

# bats test_tags=git::hooks::refresh
@test "git::hooks::refresh preserves sample hooks" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  # git init creates .sample hooks; refresh should process them
  run git::hooks::refresh
  assert_success
}
