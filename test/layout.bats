#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/layout.sh'

# Helper to create a standard cloned repo with remote tracking.
# Sets repo_dir and branch in caller's scope.
__create_cloned_repo() {
  local source_dir="${BATS_TEST_TMPDIR}/source"

  repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"

  branch="$(git -C "${repo_dir}" branch --show-current)"
}

# Helper to create a standard cloned repo with a tracked file.
# Sets repo_dir and branch in caller's scope.
__create_cloned_repo_with_file() {
  local source_dir="${BATS_TEST_TMPDIR}/source"

  repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  echo 'hello' >"${source_dir}/file.txt"
  git -C "${source_dir}" add file.txt
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'add file'

  git clone "${source_dir}" "${repo_dir}"

  branch="$(git -C "${repo_dir}" branch --show-current)"
}

# Helper to create a bare worktree structure (like git::worktree::clone produces).
# Sets project_dir, worktree_dir, and branch in caller's scope.
__create_bare_worktree_structure() {
  local source_dir="${BATS_TEST_TMPDIR}/source"

  project_dir="${BATS_TEST_TMPDIR}/project"

  git init "${source_dir}"
  echo 'hello' >"${source_dir}/file.txt"
  git -C "${source_dir}" add file.txt
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'add file'

  mkdir -p "${project_dir}/__git__"
  mkdir "${project_dir}/__context__"
  git clone --bare "${source_dir}" "${project_dir}/__git__/.git"

  # Configure remote tracking
  git -C "${project_dir}/__git__" config \
    'remote.origin.fetch' '+refs/heads/*:refs/remotes/origin/*'
  git -C "${project_dir}/__git__" fetch origin

  # Exclude __context__ symlinks
  mkdir -p "${project_dir}/__git__/.git/info"
  echo '__context__' >>"${project_dir}/__git__/.git/info/exclude"

  branch="$(git --git-dir="${project_dir}/__git__/.git" symbolic-ref --short HEAD)"
  git -C "${project_dir}/__git__" worktree add \
    "../${branch}" "${branch}"

  git -C "${project_dir}/${branch}" branch \
    --set-upstream-to="origin/${branch}" "${branch}"

  # Link context
  ln -s ../__context__ "${project_dir}/${branch}/__context__"

  worktree_dir="${project_dir}/${branch}"
}

# Helper to auto-answer 'yes' to prompts.
__to_worktree_with_yes() { echo 'y' | git::layout::to_worktree; }
export -f __to_worktree_with_yes

__to_clone_with_yes() { echo 'y' | git::layout::to_clone; }
export -f __to_clone_with_yes

################################################################################
# git::layout::to_worktree
################################################################################

# bats test_tags=git::layout::to_worktree
@test "git::layout::to_worktree fails outside a git repository" {
  cd "${BATS_TEST_TMPDIR}"

  run __to_worktree_with_yes
  assert_failure
  assert_output --partial 'Not inside a git repository'
}

# bats test_tags=git::layout::to_worktree
@test "git::layout::to_worktree fails on existing worktree structure" {
  local repo_dir branch project_dir worktree_dir

  __create_bare_worktree_structure
  cd "${worktree_dir}"

  run __to_worktree_with_yes
  assert_failure
  assert_output --partial 'Already inside a worktree linked to a bare repository'
}

# bats test_tags=git::layout::to_worktree
@test "git::layout::to_worktree fails on dirty working tree" {
  local repo_dir branch

  __create_cloned_repo_with_file
  cd "${repo_dir}"

  echo 'dirty' >file.txt

  run __to_worktree_with_yes
  assert_failure
  assert_output --partial 'Working tree is not clean'
}

# bats test_tags=git::layout::to_worktree
@test "git::layout::to_worktree fails on detached HEAD" {
  local repo_dir branch

  __create_cloned_repo
  cd "${repo_dir}"

  git checkout --detach HEAD

  run __to_worktree_with_yes
  assert_failure
  assert_output --partial 'Could not determine current branch'
}

# bats test_tags=git::layout::to_worktree
@test "git::layout::to_worktree creates bare worktree structure" {
  local repo_dir branch

  __create_cloned_repo_with_file
  cd "${repo_dir}"

  run __to_worktree_with_yes
  assert_success

  # Bare repo exists
  assert [ -f "${repo_dir}/__git__/.git/HEAD" ]

  # Worktree exists with the file
  assert [ -d "${repo_dir}/${branch}" ]
  assert [ -f "${repo_dir}/${branch}/file.txt" ]
  assert_equal "$(cat "${repo_dir}/${branch}/file.txt")" 'hello'

  # Original .git directory is gone
  assert [ ! -d "${repo_dir}/.git" ]

  # Bare repo is configured correctly
  local is_bare
  is_bare="$(git --git-dir="${repo_dir}/__git__/.git" config --get core.bare)"
  assert_equal "${is_bare}" 'true'
}

# bats test_tags=git::layout::to_worktree
@test "git::layout::to_worktree sets up context directory" {
  local repo_dir branch

  __create_cloned_repo_with_file
  cd "${repo_dir}"

  run __to_worktree_with_yes
  assert_success

  assert [ -d "${repo_dir}/__context__" ]
  assert [ -L "${repo_dir}/${branch}/__context__" ]
}

# bats test_tags=git::layout::to_worktree
@test "git::layout::to_worktree sets upstream tracking" {
  local repo_dir branch

  __create_cloned_repo_with_file
  cd "${repo_dir}"

  run __to_worktree_with_yes
  assert_success

  run git -C "${repo_dir}/${branch}" config "branch.${branch}.remote"
  assert_success
  assert_output 'origin'
}

# bats test_tags=git::layout::to_worktree
@test "git::layout::to_worktree preserves hidden files" {
  local repo_dir branch

  __create_cloned_repo_with_file
  cd "${repo_dir}"

  echo 'hidden' >.hidden_file
  git add .hidden_file
  git -c user.name=test -c user.email=test commit -m 'add hidden'

  run __to_worktree_with_yes
  assert_success

  # Hidden file should exist in worktree (checked out fresh by git worktree add)
  assert [ -f "${repo_dir}/${branch}/.hidden_file" ]
}

# bats test_tags=git::layout::to_worktree
@test "git::layout::to_worktree aborts on user decline" {
  local repo_dir branch

  __create_cloned_repo_with_file
  cd "${repo_dir}"

  __to_worktree_with_no() { echo 'n' | git::layout::to_worktree; }
  export -f __to_worktree_with_no

  run __to_worktree_with_no
  assert_success

  # Should remain unchanged
  assert [ -d "${repo_dir}/.git" ]
  assert [ ! -d "${repo_dir}/__git__" ]
}

################################################################################
# git::layout::to_clone
################################################################################

# bats test_tags=git::layout::to_clone
@test "git::layout::to_clone fails outside a git repository" {
  cd "${BATS_TEST_TMPDIR}"

  run __to_clone_with_yes
  assert_failure
  assert_output --partial 'Not inside a git repository'
}

# bats test_tags=git::layout::to_clone
@test "git::layout::to_clone fails on normal clone" {
  local repo_dir branch

  __create_cloned_repo
  cd "${repo_dir}"

  run __to_clone_with_yes
  assert_failure
  assert_output --partial 'Not inside a bare worktree structure'
}

# bats test_tags=git::layout::to_clone
@test "git::layout::to_clone fails on dirty working tree" {
  local project_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}"

  echo 'dirty' >file.txt

  run __to_clone_with_yes
  assert_failure
  assert_output --partial 'Working tree is not clean'
}

# bats test_tags=git::layout::to_clone
@test "git::layout::to_clone fails with multiple worktrees" {
  local project_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}"

  # Add a second worktree
  git worktree add "../feature" -b feature

  run __to_clone_with_yes
  assert_failure
  assert_output --partial 'Multiple worktrees exist'
}

# bats test_tags=git::layout::to_clone
@test "git::layout::to_clone converts to normal clone" {
  local project_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}"

  run __to_clone_with_yes
  assert_success

  # Normal .git directory exists
  assert [ -d "${project_dir}/.git" ]

  # File exists at project root
  assert [ -f "${project_dir}/file.txt" ]
  assert_equal "$(cat "${project_dir}/file.txt")" 'hello'

  # Bare structure is gone but __context__ is preserved
  assert [ ! -d "${project_dir}/__git__" ]
  assert [ -d "${project_dir}/__context__" ]
  assert [ ! -L "${project_dir}/__context__" ]
  assert [ ! -d "${worktree_dir}" ]

  # Not bare anymore
  local is_bare
  is_bare="$(git -C "${project_dir}" rev-parse --is-bare-repository)"
  assert_equal "${is_bare}" 'false'
}

# bats test_tags=git::layout::to_clone
@test "git::layout::to_clone aborts on user decline" {
  local project_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}"

  __to_clone_with_no() { echo 'n' | git::layout::to_clone; }
  export -f __to_clone_with_no

  run __to_clone_with_no
  assert_success

  # Should remain unchanged
  assert [ -d "${project_dir}/__git__/.git" ]
  assert [ -d "${worktree_dir}" ]
}

################################################################################
# Round-trip: clone -> worktree -> clone
################################################################################

# bats test_tags=git::layout::to_worktree,git::layout::to_clone
@test "round-trip: clone -> worktree -> clone preserves repository" {
  local repo_dir branch

  __create_cloned_repo_with_file
  cd "${repo_dir}"

  # Clone -> Worktree
  run __to_worktree_with_yes
  assert_success

  # Verify worktree structure
  assert [ -f "${repo_dir}/__git__/.git/HEAD" ]
  assert [ -f "${repo_dir}/${branch}/file.txt" ]

  # cd into the worktree for the reverse conversion
  cd "${repo_dir}/${branch}"

  # Worktree -> Clone
  run __to_clone_with_yes
  assert_success

  # Verify back to normal clone
  assert [ -d "${repo_dir}/.git" ]
  assert [ -f "${repo_dir}/file.txt" ]
  assert_equal "$(cat "${repo_dir}/file.txt")" 'hello'
  assert [ ! -d "${repo_dir}/__git__" ]

  # Git operations still work
  run git -C "${repo_dir}" log --oneline
  assert_success
}

# bats test_tags=git::layout::to_worktree,git::layout::to_clone
@test "round-trip: clone -> worktree -> clone preserves __context__" {
  local repo_dir branch

  __create_cloned_repo_with_file
  cd "${repo_dir}"

  # Clone -> Worktree
  run __to_worktree_with_yes
  assert_success

  # Put content in the shared __context__ directory
  echo 'agent notes' >"${repo_dir}/__context__/notes.md"

  # Verify __context__ is set up correctly
  assert [ -d "${repo_dir}/__context__" ]
  assert [ -L "${repo_dir}/${branch}/__context__" ]
  assert [ -f "${repo_dir}/${branch}/__context__/notes.md" ]

  # cd into the worktree for the reverse conversion
  cd "${repo_dir}/${branch}"

  # Worktree -> Clone
  run __to_clone_with_yes
  assert_success

  # __context__ dir and its content are preserved at project root
  assert [ -d "${repo_dir}/__context__" ]
  assert [ ! -L "${repo_dir}/__context__" ]
  assert [ -f "${repo_dir}/__context__/notes.md" ]
  assert_equal "$(cat "${repo_dir}/__context__/notes.md")" 'agent notes'
}

# bats test_tags=git::layout::to_worktree,git::layout::to_clone
@test "round-trip: clone -> worktree -> clone -> worktree preserves __context__" {
  local repo_dir branch

  __create_cloned_repo_with_file
  cd "${repo_dir}"

  # Clone -> Worktree
  run __to_worktree_with_yes
  assert_success

  echo 'agent notes' >"${repo_dir}/__context__/notes.md"
  cd "${repo_dir}/${branch}"

  # Worktree -> Clone
  run __to_clone_with_yes
  assert_success

  cd "${repo_dir}"

  # Clone -> Worktree (again)
  run __to_worktree_with_yes
  assert_success

  # __context__ survived the full round-trip and is re-linked
  assert [ -d "${repo_dir}/__context__" ]
  assert [ -L "${repo_dir}/${branch}/__context__" ]
  assert [ -f "${repo_dir}/${branch}/__context__/notes.md" ]
  assert_equal "$(cat "${repo_dir}/__context__/notes.md")" 'agent notes'
}

# bats test_tags=git::layout::to_worktree
@test "git::layout::to_worktree preserves existing __context__ directory" {
  local repo_dir branch

  __create_cloned_repo_with_file
  cd "${repo_dir}"

  # Pre-create a __context__ directory (simulating a prior conversion)
  mkdir "${repo_dir}/__context__"
  echo 'preserved' >"${repo_dir}/__context__/data.txt"

  run __to_worktree_with_yes
  assert_success

  # __context__ is preserved and linked into worktree
  assert [ -d "${repo_dir}/__context__" ]
  assert [ -f "${repo_dir}/__context__/data.txt" ]
  assert_equal "$(cat "${repo_dir}/__context__/data.txt")" 'preserved'
  assert [ -L "${repo_dir}/${branch}/__context__" ]
  assert [ -f "${repo_dir}/${branch}/__context__/data.txt" ]
}
