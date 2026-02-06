#!/usr/bin/env bats

load ../test_helper

setup_with_coverage 'git-friends/src/hooks/pre_commit.sh'

################################################################################
# git::hooks::pre_commit
################################################################################

# bats test_tags=git::hooks::pre_commit
@test "git::hooks::pre_commit returns early when nothing is staged" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'
  cd "${repo_dir}"

  run git::hooks::pre_commit
  assert_success
  refute_output
}

# bats test_tags=git::hooks::pre_commit
@test "git::hooks::pre_commit returns early when no rules found" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'
  cd "${repo_dir}"

  # Stage a file so git diff --cached is non-empty
  printf 'test content\n' > 'testfile.txt'
  git add 'testfile.txt'

  run git::hooks::pre_commit
  assert_success
}

# bats test_tags=git::hooks::pre_commit
@test "git::hooks::pre_commit exits early when disabled" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'
  git -C "${repo_dir}" config 'git-friends.pre-commit.disabled' true
  cd "${repo_dir}"

  # Create a rule script and stage a file
  printf '#!/bin/bash\nexit 0\n' > '.git/hooks/pre-commit-test-lint'
  chmod +x '.git/hooks/pre-commit-test-lint'
  printf 'test content\n' > 'testfile.txt'
  git add 'testfile.txt'

  run git::hooks::pre_commit
  assert_success
}

################################################################################
# git::hooks::pre_commit::block
################################################################################

# bats test_tags=git::hooks::pre_commit::block
@test "git::hooks::pre_commit::block runs rule without flags when not in skip list" {
  local \
    logfile="${BATS_TEST_TMPDIR}/test.log" \
    rule="${BATS_TEST_TMPDIR}/pre-commit-test-lint"

  printf '#!/bin/bash\necho "lint passed"\n' > "${rule}"
  chmod +x "${rule}"

  run git::hooks::pre_commit::block \
    "${rule}" \
    "${logfile}"
  assert_success
  assert_line 'lint passed'
}

# bats test_tags=git::hooks::pre_commit::block
@test "git::hooks::pre_commit::block runs rule with -n flag when in skip list" {
  local \
    logfile="${BATS_TEST_TMPDIR}/test.log" \
    rule="${BATS_TEST_TMPDIR}/pre-commit-test-lint"

  printf '#!/bin/bash\necho "flags: $*"\n' > "${rule}"
  chmod +x "${rule}"

  run git::hooks::pre_commit::block \
    "${rule}" \
    "${logfile}" \
    'lint'
  assert_success
  assert_line 'flags: -n'
}

# bats test_tags=git::hooks::pre_commit::block
@test "git::hooks::pre_commit::block does not add -n flag when rule name not in skip list" {
  local \
    logfile="${BATS_TEST_TMPDIR}/test.log" \
    rule="${BATS_TEST_TMPDIR}/pre-commit-test-lint"

  printf '#!/bin/bash\necho "ran without flags"\n' > "${rule}"
  chmod +x "${rule}"

  run git::hooks::pre_commit::block \
    "${rule}" \
    "${logfile}" \
    'other-rule'
  assert_success
  assert_line 'ran without flags'
}

# bats test_tags=git::hooks::pre_commit::block
@test "git::hooks::pre_commit::block propagates rule failure" {
  local \
    logfile="${BATS_TEST_TMPDIR}/test.log" \
    rule="${BATS_TEST_TMPDIR}/pre-commit-test-check"

  printf '#!/bin/bash\nexit 1\n' > "${rule}"
  chmod +x "${rule}"

  run git::hooks::pre_commit::block \
    "${rule}" \
    "${logfile}"
  assert_failure
}

# bats test_tags=git::hooks::pre_commit::block
@test "git::hooks::pre_commit::block handles rule with dotted extension in name" {
  local \
    logfile="${BATS_TEST_TMPDIR}/test.log" \
    rule="${BATS_TEST_TMPDIR}/pre-commit-test-mycheck.sh"

  printf '#!/bin/bash\necho "flags: $*"\n' > "${rule}"
  chmod +x "${rule}"

  run git::hooks::pre_commit::block \
    "${rule}" \
    "${logfile}" \
    'mycheck'
  assert_success
  assert_line 'flags: -n'
}

# bats test_tags=git::hooks::pre_commit::block
@test "git::hooks::pre_commit::block runs without skip list" {
  local \
    logfile="${BATS_TEST_TMPDIR}/test.log" \
    rule="${BATS_TEST_TMPDIR}/pre-commit-test-unit"

  printf '#!/bin/bash\necho "unit tests passed"\n' > "${rule}"
  chmod +x "${rule}"

  run git::hooks::pre_commit::block \
    "${rule}" \
    "${logfile}"
  assert_success
  assert_line 'unit tests passed'
}
