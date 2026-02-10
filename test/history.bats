#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/history.sh'

################################################################################
# git::history::churn
################################################################################

# bats test_tags=git::history::churn
@test "git::history::churn outputs file change counts" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  printf 'content\n' > 'file.txt'
  git add 'file.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'add file'

  printf 'modified\n' > 'file.txt'
  git add 'file.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'modify file'

  run git::history::churn
  assert_success
  assert_line 'count file'
  assert_output --partial 'file.txt'
}

# bats test_tags=git::history::churn
@test "git::history::churn outputs header with no file changes" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  git -c user.name=test -c user.email=test \
    commit --allow-empty -m 'empty'

  run git::history::churn
  assert_success
  assert_output 'count file'
}

# bats test_tags=git::history::churn
@test "git::history::churn passes extra arguments to git log" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  printf 'content\n' > 'file.txt'
  git add 'file.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'add file'

  printf 'more\n' > 'other.txt'
  git add 'other.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'add other'

  run git::history::churn -1
  assert_success
  assert_output --partial 'other.txt'
  refute_output --partial 'file.txt'
}

################################################################################
# git::history::recent
################################################################################

# bats test_tags=git::history::recent
@test "git::history::recent outputs branch information" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  # Use -b main: Docker git lacks init.defaultBranch and defaults to 'master'
  git init -b main "${repo_dir}"
  cd "${repo_dir}"

  printf 'content\n' > 'file.txt'
  git add 'file.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'initial commit'

  run git::history::recent
  assert_success
  assert_output --partial 'main'
}

# bats test_tags=git::history::recent
@test "git::history::recent with count limits output" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  # Use -b main: Docker git lacks init.defaultBranch and defaults to 'master'
  git init -b main "${repo_dir}"
  cd "${repo_dir}"

  printf 'content\n' > 'file.txt'
  git add 'file.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'initial commit'

  git checkout -b 'feature-a'
  printf 'a\n' > 'a.txt'
  git add 'a.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'feature a commit'

  git checkout -b 'feature-b'
  printf 'b\n' > 'b.txt'
  git add 'b.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'feature b commit'

  run git::history::recent 1
  assert_success
}

