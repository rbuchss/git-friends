#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/cd.sh'

################################################################################
# git::cd::root_dir
################################################################################

# bats test_tags=git::cd::root_dir
@test "git::cd::root_dir changes to repository root" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"

  # Resolve symlinks (macOS /var -> /private/var) to match git rev-parse output
  repo_dir="$(cd "${repo_dir}" && pwd -P)"

  mkdir -p "${repo_dir}/a/b/c"
  cd "${repo_dir}/a/b/c"

  git::cd::root_dir

  assert_equal "${PWD}" "${repo_dir}"
}

# bats test_tags=git::cd::root_dir
@test "git::cd::root_dir fails outside a git repo" {
  cd "${BATS_TEST_TMPDIR}"

  run git::cd::root_dir
  assert_failure
}
