#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/log.sh'

# Helper to create a repo with commits.
# Sets repo_dir in caller's scope.
__create_repo_with_commits() {
  local source_dir="${BATS_TEST_TMPDIR}/source"

  repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'first commit'
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'second commit'

  git clone "${source_dir}" "${repo_dir}"
}

################################################################################
# git::log::basic
################################################################################

# bats test_tags=git::log::basic
@test "git::log::basic outputs formatted log" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  run git::log::basic
  assert_success
  assert_output --regexp 'second commit'
  assert_output --regexp 'first commit'
}

# bats test_tags=git::log::basic
@test "git::log::basic passes extra arguments through" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  run git::log::basic -1
  assert_success
  assert_output --regexp 'second commit'
  refute_output --regexp 'first commit'
}

# bats test_tags=git::log::basic
@test "git::log::basic includes date with --date flag" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  run git::log::basic --date=short -1
  assert_success
  # Date format should be present (YYYY-MM-DD)
  assert_output --regexp '[0-9]{4}-[0-9]{2}-[0-9]{2}'
}

################################################################################
# git::log::pretty
################################################################################

# bats test_tags=git::log::pretty
@test "git::log::pretty outputs graph log" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  run git::log::pretty
  assert_success
  assert_output --regexp 'second commit'
}

# bats test_tags=git::log::pretty
@test "git::log::pretty passes extra arguments through with graph" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  run git::log::pretty -1
  assert_success
  assert_output --regexp 'second commit'
  refute_output --regexp 'first commit'
}

# bats test_tags=git::log::basic
@test "git::log::basic includes date with --relative-date flag" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  run git::log::basic --relative-date -1
  assert_success
  assert_output --regexp 'second commit'
}

################################################################################
# git::log::from_default_branch
################################################################################

# bats test_tags=git::log::from_default_branch
@test "git::log::from_default_branch passes through range argument" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  run git::log::from_default_branch 'HEAD~1..HEAD'
  assert_success
  assert_output --regexp 'second commit'
  refute_output --regexp 'first commit'
}

# bats test_tags=git::log::from_default_branch
@test "git::log::from_default_branch uses default branch range" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  git checkout -b 'feature'
  git -c user.name=test -c user.email=test \
    commit --allow-empty -m 'feature commit'

  run git::log::from_default_branch
  assert_success
  assert_output --regexp 'feature commit'
}

# bats test_tags=git::log::from_default_branch
@test "git::log::from_default_branch passes extra args with default branch range" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  git checkout -b 'feature'
  git -c user.name=test -c user.email=test \
    commit --allow-empty -m 'feature commit'
  git -c user.name=test -c user.email=test \
    commit --allow-empty -m 'another feature commit'

  run git::log::from_default_branch -1
  assert_success
  assert_output --regexp 'feature commit'
}

# bats test_tags=git::log::basic
@test "git::log::basic includes date with --date space-separated flag" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  run git::log::basic --date short -1
  assert_success
  # Date format should be present (YYYY-MM-DD)
  assert_output --regexp '[0-9]{4}-[0-9]{2}-[0-9]{2}'
}

################################################################################
# git::log::basic (no date flag)
################################################################################

# bats test_tags=git::log::basic
@test "git::log::basic without date flag omits date from output" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  run git::log::basic -1
  assert_success
  # Without a date flag, output should NOT contain a date pattern
  refute_output --regexp '[0-9]{4}-[0-9]{2}-[0-9]{2}'
}

# bats test_tags=git::log::from_default_branch
@test "git::log::from_default_branch with triple-dot range passes through" {
  local repo_dir

  __create_repo_with_commits
  cd "${repo_dir}"

  run git::log::from_default_branch 'HEAD~1...HEAD'
  assert_success
}
