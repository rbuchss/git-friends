#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/utility.sh'

# Helper to create a regular repo with a commit.
# Sets repo_dir in caller's scope.
__create_repo() {
  repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'
}

# Helper to create a cloned repo with remote tracking refs.
# Sets repo_dir in caller's scope.
__create_cloned_repo() {
  local source_dir="${BATS_TEST_TMPDIR}/source"

  repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"
}

# Helper to create a bare repo with a linked worktree.
# Sets bare_dir and worktree_dir in caller's scope.
__create_bare_with_worktree() {
  local \
    source_dir="${BATS_TEST_TMPDIR}/source" \
    branch

  bare_dir="${BATS_TEST_TMPDIR}/bare"
  worktree_dir="${BATS_TEST_TMPDIR}/worktree"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone --bare "${source_dir}" "${bare_dir}"

  branch="$(git --git-dir="${bare_dir}" symbolic-ref --short HEAD)"
  git --git-dir="${bare_dir}" worktree add "${worktree_dir}" "${branch}"
}

################################################################################
# git::utility::ask
################################################################################

@test "git::utility::ask 'build snowman?' <<< 'y'" {
  run git::utility::ask 'build snowman?' <<< 'y'

  assert_success
}

@test "git::utility::ask 'build snowman?' <<< 'Y'" {
  run git::utility::ask 'build snowman?' <<< 'Y'

  assert_success
}

@test "git::utility::ask 'build snowman?' <<< 'Yes'" {
  run git::utility::ask 'build snowman?' <<< 'Yes'

  assert_success
}

@test "git::utility::ask 'build snowman?' <<< 'yes'" {
  run git::utility::ask 'build snowman?' <<< 'yes'

  assert_success
}

@test "git::utility::ask 'build snowman?' <<< 'n'" {
  run git::utility::ask 'build snowman?' <<< 'n'

  assert_failure
}

@test "git::utility::ask 'build snowman?' <<< 'N'" {
  run git::utility::ask 'build snowman?' <<< 'N'

  assert_failure
}

@test "git::utility::ask 'build snowman?' <<< 'No'" {
  run git::utility::ask 'build snowman?' <<< 'No'

  assert_failure
}

@test "git::utility::ask 'build snowman?' <<< 'no'" {
  run git::utility::ask 'build snowman?' <<< 'no'

  assert_failure
}

@test "git::utility::ask 'build snowman?' <<< 'unknown'" {
  run git::utility::ask 'build snowman?' <<< 'unknown'

  assert_failure
}

@test "git::utility::ask 'build snowman?' all_response <<< 'y'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'y' \
    || _status="$?"

  assert_equal "${_status}" 0
  assert [ -z "${all_response}" ]
}

@test "git::utility::ask 'build snowman?' all_response <<< 'yes'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'yes' \
    || _status="$?"

  assert_equal "${_status}" 0
  assert [ -z "${all_response}" ]
}

@test "git::utility::ask 'build snowman?' all_response <<< 'n'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'n' \
    || _status="$?"

  assert_equal "${_status}" 1
  assert [ -z "${all_response}" ]
}

@test "git::utility::ask 'build snowman?' all_response <<< 'no'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'no' \
    || _status="$?"

  assert_equal "${_status}" 1
  assert [ -z "${all_response}" ]
}

@test "git::utility::ask 'build snowman?' all_response <<< 'yarp'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'yarp' \
    || _status="$?"

  assert_equal "${_status}" 1
  assert [ -z "${all_response}" ]
}

@test "git::utility::ask 'build snowman?' all_response <<< 'a'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'a' \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${all_response}" 0

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${all_response}" 0
}

@test "git::utility::ask 'build snowman?' all_response <<< 'all'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'all'\
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${all_response}" 0

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${all_response}" 0
}

@test "git::utility::ask 'build snowman?' all_response <<< 'z'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'z' \
    || _status="$?"

  assert_equal "${_status}" 1
  assert_equal "${all_response}" 1

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 1
  assert_equal "${all_response}" 1
}

@test "git::utility::ask 'build snowman?' all_response <<< 'none'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'none' \
    || _status="$?"

  assert_equal "${_status}" 1
  assert_equal "${all_response}" 1

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 1
  assert_equal "${all_response}" 1
}

@test "git::utility::ask 'build snowman?' all_response=0" {
  local \
    all_response=0 \
    _status=0

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${all_response}" 0
}

@test "git::utility::ask 'build snowman?' all_response=1" {
  local \
    all_response=1 \
    _status=0

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 1
  assert_equal "${all_response}" 1
}

################################################################################
# git::utility::array_contains
################################################################################

# bats test_tags=git::utility::array_contains
@test "git::utility::array_contains returns success when element exists" {
  run git::utility::array_contains 'b' 'a' 'b' 'c'
  assert_success
}

# bats test_tags=git::utility::array_contains
@test "git::utility::array_contains returns success for first element" {
  run git::utility::array_contains 'a' 'a' 'b' 'c'
  assert_success
}

# bats test_tags=git::utility::array_contains
@test "git::utility::array_contains returns success for last element" {
  run git::utility::array_contains 'c' 'a' 'b' 'c'
  assert_success
}

# bats test_tags=git::utility::array_contains
@test "git::utility::array_contains returns failure when element missing" {
  run git::utility::array_contains 'd' 'a' 'b' 'c'
  assert_failure
}

# bats test_tags=git::utility::array_contains
@test "git::utility::array_contains returns failure for empty array" {
  run git::utility::array_contains 'a'
  assert_failure
}

################################################################################
# git::utility::is_executable
################################################################################

# bats test_tags=git::utility::is_executable
@test "git::utility::is_executable returns success for shell builtin" {
  run git::utility::is_executable 'echo'
  assert_success
}

# bats test_tags=git::utility::is_executable
@test "git::utility::is_executable returns success for command on PATH" {
  run git::utility::is_executable 'git'
  assert_success
}

# bats test_tags=git::utility::is_executable
@test "git::utility::is_executable returns success for defined function" {
  run git::utility::is_executable 'git::utility::is_executable'
  assert_success
}

# bats test_tags=git::utility::is_executable
@test "git::utility::is_executable returns failure for unknown command" {
  run git::utility::is_executable '__nonexistent_command__'
  assert_failure
}

################################################################################
# git::utility::is_not_executable
################################################################################

# bats test_tags=git::utility::is_not_executable
@test "git::utility::is_not_executable returns success for unknown command" {
  run git::utility::is_not_executable '__nonexistent_command__'
  assert_success
}

# bats test_tags=git::utility::is_not_executable
@test "git::utility::is_not_executable returns failure for known command" {
  run git::utility::is_not_executable 'git'
  assert_failure
}

################################################################################
# git::utility::main_branch_names
################################################################################

# bats test_tags=git::utility::main_branch_names
@test "git::utility::main_branch_names sets default branch names" {
  local result

  unset GIT_FRIENDS_MAIN_BRANCH_NAMES
  git::utility::main_branch_names result

  assert_equal "${#result[@]}" 3
  assert_equal "${result[0]}" 'master'
  assert_equal "${result[1]}" 'main'
  assert_equal "${result[2]}" 'mainline'
}

# bats test_tags=git::utility::main_branch_names
@test "git::utility::main_branch_names reads from GIT_FRIENDS_MAIN_BRANCH_NAMES" {
  local result

  GIT_FRIENDS_MAIN_BRANCH_NAMES='develop trunk'
  git::utility::main_branch_names result

  assert_equal "${#result[@]}" 2
  assert_equal "${result[0]}" 'develop'
  assert_equal "${result[1]}" 'trunk'
}

# bats test_tags=git::utility::main_branch_names
@test "git::utility::main_branch_names handles single branch name" {
  local result

  GIT_FRIENDS_MAIN_BRANCH_NAMES='main'
  git::utility::main_branch_names result

  assert_equal "${#result[@]}" 1
  assert_equal "${result[0]}" 'main'
}

# bats test_tags=git::utility::main_branch_names
@test "git::utility::main_branch_names overwrites previous values" {
  local result

  GIT_FRIENDS_MAIN_BRANCH_NAMES='first'
  git::utility::main_branch_names result
  assert_equal "${result[0]}" 'first'

  # shellcheck disable=SC2034
  GIT_FRIENDS_MAIN_BRANCH_NAMES='second third'
  git::utility::main_branch_names result
  assert_equal "${#result[@]}" 2
  assert_equal "${result[0]}" 'second'
  assert_equal "${result[1]}" 'third'
}

################################################################################
# git::utility::get_main_ref
################################################################################

# bats test_tags=git::utility::get_main_ref
@test "git::utility::get_main_ref returns remote ref for cloned repo" {
  local repo_dir

  __create_cloned_repo

  run git::utility::get_main_ref 'origin' "${repo_dir}"
  assert_success
  assert_output --regexp '^origin/(main|master|mainline)$'
}

# bats test_tags=git::utility::get_main_ref
@test "git::utility::get_main_ref falls back to local ref for bare repo" {
  local repo_dir

  __create_repo

  run git::utility::get_main_ref 'origin' "${repo_dir}"
  assert_failure
}

# bats test_tags=git::utility::get_main_ref
@test "git::utility::get_main_ref returns failure when no branch found" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" checkout -b 'unrelated-branch'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  run git::utility::get_main_ref 'origin' "${repo_dir}"
  assert_failure
}

################################################################################
# git::utility::get_main_ref::remote
################################################################################

# bats test_tags=git::utility::get_main_ref::remote
@test "git::utility::get_main_ref::remote finds remote tracking branch" {
  local repo_dir

  __create_cloned_repo

  run git::utility::get_main_ref::remote 'origin' "${repo_dir}"
  assert_success
  assert_output --regexp '^origin/(main|master|mainline)$'
}

# bats test_tags=git::utility::get_main_ref::remote
@test "git::utility::get_main_ref::remote returns failure for bare repo without remote refs" {
  local bare_dir="${BATS_TEST_TMPDIR}/bare"

  git init --bare "${bare_dir}"

  run git::utility::get_main_ref::remote 'origin' "${bare_dir}"
  assert_failure
}

################################################################################
# git::utility::get_main_ref::local
################################################################################

# bats test_tags=git::utility::get_main_ref::local
@test "git::utility::get_main_ref::local finds local branch" {
  local repo_dir

  __create_repo

  run git::utility::get_main_ref::local "${repo_dir}"
  assert_success
  assert_output --regexp '^(main|master|mainline)$'
}

# bats test_tags=git::utility::get_main_ref::local
@test "git::utility::get_main_ref::local returns failure when no matching branch" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" checkout -b 'unrelated-branch'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  run git::utility::get_main_ref::local "${repo_dir}"
  assert_failure
}

################################################################################
# git::utility::is_bare_or_worktree
################################################################################

# bats test_tags=git::utility::is_bare_or_worktree
@test "git::utility::is_bare_or_worktree returns success for bare repo" {
  local bare_dir="${BATS_TEST_TMPDIR}/bare"

  git init --bare "${bare_dir}"

  run git::utility::is_bare_or_worktree "${bare_dir}"
  assert_success
}

# bats test_tags=git::utility::is_bare_or_worktree
@test "git::utility::is_bare_or_worktree returns success for worktree of bare repo" {
  local bare_dir worktree_dir

  __create_bare_with_worktree

  run git::utility::is_bare_or_worktree "${worktree_dir}"
  assert_success
}

# bats test_tags=git::utility::is_bare_or_worktree
@test "git::utility::is_bare_or_worktree returns failure for regular repo" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"

  run git::utility::is_bare_or_worktree "${repo_dir}"
  assert_failure
}

################################################################################
# git::utility::is_bare
################################################################################

# bats test_tags=git::utility::is_bare
@test "git::utility::is_bare returns success for bare repo" {
  local bare_dir="${BATS_TEST_TMPDIR}/bare"

  git init --bare "${bare_dir}"

  run git::utility::is_bare "${bare_dir}"
  assert_success
}

# bats test_tags=git::utility::is_bare
@test "git::utility::is_bare returns failure for regular repo" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"

  run git::utility::is_bare "${repo_dir}"
  assert_failure
}

# bats test_tags=git::utility::is_bare
@test "git::utility::is_bare returns failure for worktree of bare repo" {
  local bare_dir worktree_dir

  __create_bare_with_worktree

  run git::utility::is_bare "${worktree_dir}"
  assert_failure
}

################################################################################
# git::utility::is_worktree
################################################################################

# bats test_tags=git::utility::is_worktree
@test "git::utility::is_worktree returns success for worktree of bare repo" {
  local bare_dir worktree_dir

  __create_bare_with_worktree

  run git::utility::is_worktree "${worktree_dir}"
  assert_success
}

# bats test_tags=git::utility::is_worktree
@test "git::utility::is_worktree returns failure for bare repo" {
  local bare_dir="${BATS_TEST_TMPDIR}/bare"

  git init --bare "${bare_dir}"

  run git::utility::is_worktree "${bare_dir}"
  assert_failure
}

# bats test_tags=git::utility::is_worktree
@test "git::utility::is_worktree returns failure for regular repo" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"

  run git::utility::is_worktree "${repo_dir}"
  assert_failure
}
