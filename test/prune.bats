#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/prune.sh'

# Helper to create a repo with merged branches.
# Sets repo_dir in caller's scope.
__create_repo_with_merged_branches() {
  repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  # Save main branch name before switching
  local main_branch
  main_branch="$(git -C "${repo_dir}" branch --show-current)"

  # Create and merge a branch
  git -C "${repo_dir}" checkout -b 'merged-feature'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'feature commit'

  git -C "${repo_dir}" checkout "${main_branch}"
  git -C "${repo_dir}" merge 'merged-feature'
}

################################################################################
# git::prune::branches::usage
################################################################################

# bats test_tags=git::prune::branches::usage
@test "git::prune::branches::usage outputs help text" {
  run git::prune::branches::usage
  assert_success
  assert_output --regexp 'Usage:'
  assert_output --regexp '--all'
  assert_output --regexp '--force'
  assert_output --regexp '--local'
  assert_output --regexp '--remote'
}

################################################################################
# git::prune::branches
################################################################################

# bats test_tags=git::prune::branches
@test "git::prune::branches fails with invalid option" {
  run git::prune::branches --invalid
  assert_failure
}

# bats test_tags=git::prune::branches
@test "git::prune::branches defaults to local mode" {
  local repo_dir

  __create_repo_with_merged_branches
  cd "${repo_dir}"

  # Force mode so no prompt; no merged branches except the one we created
  run git::prune::branches --force
  assert_success
}

################################################################################
# git::prune::branches::local
################################################################################

# bats test_tags=git::prune::branches::local
@test "git::prune::branches::local returns success with no merged branches" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'
  cd "${repo_dir}"

  run git::prune::branches::local 1
  assert_success
}

# bats test_tags=git::prune::branches::local
@test "git::prune::branches::local fails with nonexistent ref branch" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'
  cd "${repo_dir}"

  run git::prune::branches::local 1 'nonexistent'
  assert_failure
}

# bats test_tags=git::prune::branches::local
@test "git::prune::branches::local removes merged branches with force" {
  local repo_dir

  __create_repo_with_merged_branches
  cd "${repo_dir}"

  # Verify branch exists
  git branch | grep -q 'merged-feature'

  run git::prune::branches::local 1
  assert_success

  # Branch should be deleted
  ! git branch | grep -q 'merged-feature'
}

################################################################################
# git::prune::branches::remote
################################################################################

# bats test_tags=git::prune::branches::remote
@test "git::prune::branches::remote fails with invalid remote" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::prune::branches::remote 1 'nonexistent'
  assert_failure
}

# bats test_tags=git::prune::branches::remote
@test "git::prune::branches::remote succeeds with nothing to prune" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"
  cd "${repo_dir}"

  run git::prune::branches::remote 1
  assert_success
}

################################################################################
# git::prune::branches::all
################################################################################

# bats test_tags=git::prune::branches::all
@test "git::prune::branches::all fails with only 2 arguments" {
  run git::prune::branches::all 1 'origin'
  assert_failure
}

# bats test_tags=git::prune::branches::all
@test "git::prune::branches::all succeeds with valid arguments" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"
  cd "${repo_dir}"

  local branch
  branch="$(git branch --show-current)"

  run git::prune::branches::all 1 'origin' "${branch}"
  assert_success
}

################################################################################
# git::prune::branches (flag routing)
################################################################################

# bats test_tags=git::prune::branches
@test "git::prune::branches --remote routes to remote mode" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"
  cd "${repo_dir}"

  run git::prune::branches --force --remote
  assert_success
}

# bats test_tags=git::prune::branches
@test "git::prune::branches --all --force routes to all mode" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/cloned"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  git clone "${source_dir}" "${repo_dir}"
  cd "${repo_dir}"

  run git::prune::branches --force --all
  assert_success
}

# bats test_tags=git::prune::branches
@test "git::prune::branches --local is explicit default" {
  local repo_dir

  __create_repo_with_merged_branches
  cd "${repo_dir}"

  run git::prune::branches --force --local
  assert_success
}

# bats test_tags=git::prune::branches
@test "git::prune::branches passes positional arguments through" {
  local repo_dir

  __create_repo_with_merged_branches
  cd "${repo_dir}"
  local main_branch
  main_branch="$(git branch --show-current)"

  # Pass the ref branch as a positional argument (hits case * -> arguments+=)
  run git::prune::branches --force "${main_branch}"
  assert_success
}

# bats test_tags=git::prune::branches::remote
@test "git::prune::branches::remote force prunes stale tracking refs" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local repo_dir="${BATS_TEST_TMPDIR}/prune-stale"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  local main_branch
  main_branch="$(git -C "${source_dir}" branch --show-current)"

  # Create a branch in source that we'll later delete to make it stale
  git -C "${source_dir}" checkout -b 'stale-branch'
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'stale commit'
  git -C "${source_dir}" checkout "${main_branch}"

  git clone "${source_dir}" "${repo_dir}"

  # Delete the branch from source to create stale tracking ref
  git -C "${source_dir}" branch -D 'stale-branch'

  cd "${repo_dir}"

  run git::prune::branches::remote 1
  assert_success
}
