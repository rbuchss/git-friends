#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/invoke.sh'

# Helper to create a cloned repo (non-bare) with remote tracking.
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

# Helper to create a bare worktree structure (like git::worktree::clone produces).
# Sets bare_dir, worktree_dir, and branch in caller's scope.
__create_bare_worktree_structure() {
  local source_dir="${BATS_TEST_TMPDIR}/source"

  bare_dir="${BATS_TEST_TMPDIR}/project/__git__/.git"
  worktree_dir="${BATS_TEST_TMPDIR}/project"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  mkdir -p "${BATS_TEST_TMPDIR}/project/__git__"
  mkdir "${BATS_TEST_TMPDIR}/project/__context__"
  git clone --bare "${source_dir}" "${bare_dir}"

  mkdir -p "${bare_dir}/info"
  echo '__context__' >>"${bare_dir}/info/exclude"

  git -C "${BATS_TEST_TMPDIR}/project/__git__" config \
    'remote.origin.fetch' '+refs/heads/*:refs/remotes/origin/*'
  git -C "${BATS_TEST_TMPDIR}/project/__git__" fetch origin

  branch="$(git --git-dir="${bare_dir}" symbolic-ref --short HEAD)"
  git -C "${BATS_TEST_TMPDIR}/project/__git__" worktree add \
    "../${branch}" "${branch}"

  git -C "${worktree_dir}/${branch}" branch \
    --set-upstream-to="origin/${branch}" "${branch}"
}

################################################################################
# git::invoke cld / wcld dispatch
################################################################################

# bats test_tags=git::invoke
@test "git::invoke cld dispatches to git::clone::cd" {
  git::clone::cd() { echo "clone-cd: $*"; }
  export -f git::clone::cd

  run git::invoke cld 'https://example.com/repo.git'
  assert_success
  assert_output 'clone-cd: https://example.com/repo.git'
}

# bats test_tags=git::invoke
@test "git::invoke wcld dispatches to git::worktree::clone::cd" {
  git::worktree::clone::cd() { echo "worktree-clone-cd: $*"; }
  export -f git::worktree::clone::cd

  run git::invoke wcld 'https://example.com/repo.git'
  assert_success
  assert_output 'worktree-clone-cd: https://example.com/repo.git'
}

################################################################################
# git::invoke::__enable__ / __disable__
################################################################################

# bats test_tags=git::invoke
@test "git::invoke::__enable__ registers completion via complete -F" {
  unset -f __git_complete 2>/dev/null

  git::invoke::__enable__

  alias git | grep -q 'git::invoke'
  alias g | grep -q 'git::invoke'
  complete -p git | grep -q 'git::invoke::__complete__'
  complete -p g | grep -q 'git::invoke::__complete__'

  git::invoke::__disable__
}

# bats test_tags=git::invoke
@test "git::invoke::__enable__ registers completion via __git_complete" {
  __git_complete() { complete -F "$2" "$1"; }

  git::invoke::__enable__

  complete -p git | grep -q 'git::invoke::__complete__'
  complete -p g | grep -q 'git::invoke::__complete__'

  git::invoke::__disable__
  unset -f __git_complete
}

# bats test_tags=git::invoke
@test "git::invoke::__disable__ removes completion registrations and aliases" {
  git::invoke::__enable__
  git::invoke::__disable__

  ! complete -p git 2>/dev/null
  ! complete -p g 2>/dev/null
  ! alias git 2>/dev/null
  ! alias g 2>/dev/null
}

################################################################################
# git::invoke (passthrough)
################################################################################

# bats test_tags=git::invoke
@test "git::invoke passes through to git for unknown subcommands" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::invoke status --short
  assert_success
}

# bats test_tags=git::invoke
@test "git::invoke passes through git aliases" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::invoke branch --list
  assert_success
}

################################################################################
# git::invoke cd
################################################################################

# bats test_tags=git::invoke
@test "git::invoke cd changes to repository root" {
  local repo_dir

  __create_cloned_repo

  # Create and cd into a subdirectory
  mkdir -p "${repo_dir}/sub/dir"
  cd "${repo_dir}/sub/dir"

  git::invoke cd

  # Resolve symlinks for macOS /var -> /private/var
  assert_equal "$(pwd -P)" "$(cd "${repo_dir}" && pwd -P)"
}

################################################################################
# git::invoke wco
################################################################################

# bats test_tags=git::invoke
@test "git::invoke wco creates worktree and changes directory" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git branch 'g-wco-test'

  git::invoke wco 'g-wco-test'

  assert_equal "${PWD}" "${worktree_dir}/g-wco-test"
}

################################################################################
# git::invoke init-context
################################################################################

# bats test_tags=git::invoke
@test "git::invoke init-context initializes context" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure

  # Remove __context__ to test init-context creates it
  rm -rf "${worktree_dir}/__context__"
  cd "${worktree_dir}/${branch}"

  git::invoke init-context

  assert [ -d "${worktree_dir}/__context__" ]
  assert [ -L "${worktree_dir}/${branch}/__context__" ]
}
