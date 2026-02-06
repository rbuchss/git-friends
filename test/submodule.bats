#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/submodule.sh'

bats_require_minimum_version 1.5.0

# Helper to create a git repo with no submodules.
# Sets repo_dir in caller's scope.
__create_repo() {
  repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'
}

# Helper to create a git repo with a submodule.
# Sets repo_dir and sub_path in caller's scope.
__create_repo_with_submodule() {
  local sub_source="${BATS_TEST_TMPDIR}/sub-source"

  repo_dir="${BATS_TEST_TMPDIR}/repo"
  sub_path='vendor/sub'

  git init "${sub_source}"
  git -C "${sub_source}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git init "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git -C "${repo_dir}" \
    -c protocol.file.allow=always \
    submodule add "${sub_source}" "${sub_path}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'add submodule'
}

################################################################################
# git::submodule::sync
################################################################################

# bats test_tags=git::submodule::sync
@test "git::submodule::sync with no args runs update --init --recursive" {
  local repo_dir

  __create_repo
  cd "${repo_dir}"

  run git::submodule::sync
  assert_success
}

# bats test_tags=git::submodule::sync
@test "git::submodule::sync with path takes path argument" {
  local repo_dir sub_path

  __create_repo_with_submodule
  cd "${repo_dir}"

  run git::submodule::sync "${sub_path}"
  assert_success
}

################################################################################
# git::submodule::upgrade
################################################################################

# bats test_tags=git::submodule::upgrade
@test "git::submodule::upgrade with no args runs update --recursive --remote" {
  local repo_dir

  __create_repo
  cd "${repo_dir}"

  run git::submodule::upgrade
  assert_success
}

# bats test_tags=git::submodule::upgrade
@test "git::submodule::upgrade with path takes path argument" {
  local repo_dir sub_path

  __create_repo_with_submodule
  cd "${repo_dir}"

  # Allow file:// protocol for local submodule fetch
  GIT_CONFIG_COUNT=1 \
  GIT_CONFIG_KEY_0='protocol.file.allow' \
  GIT_CONFIG_VALUE_0='always' \
  run git::submodule::upgrade "${sub_path}"
  assert_success
}

################################################################################
# git::submodule::remove
################################################################################

# bats test_tags=git::submodule::remove
@test "git::submodule::remove with nonexistent path returns failure" {
  local repo_dir

  __create_repo
  cd "${repo_dir}"

  run git::submodule::remove 'nonexistent/path'
  assert_failure
}

# bats test_tags=git::submodule::remove
@test "git::submodule::remove with nonexistent path logs error" {
  local repo_dir

  __create_repo
  cd "${repo_dir}"

  run --separate-stderr git::submodule::remove 'does/not/exist'
  assert_failure
  assert_stderr --partial "path to submodule: 'does/not/exist' not found"
}
