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

# Helper to create a repo with a squash-merged branch.
# The branch's changes are squashed onto the main branch as a single commit, so
# the branch is patch-equivalent to main but NOT an ancestor of it (git branch
# --merged does not list it and git branch -d refuses it). Sets repo_dir in the
# caller's scope and leaves the main branch checked out.
__create_repo_with_squash_merged_branch() {
  repo_dir="${BATS_TEST_TMPDIR}/squash-repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  local main_branch
  main_branch="$(git -C "${repo_dir}" branch --show-current)"

  git -C "${repo_dir}" checkout -b 'squashed-feature'
  echo 'feature content' >"${repo_dir}/feature.txt"
  git -C "${repo_dir}" add feature.txt
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'feature work'

  git -C "${repo_dir}" checkout "${main_branch}"
  git -C "${repo_dir}" merge --squash 'squashed-feature'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'squashed feature'
}

# Add a divergent branch carrying real, unmerged work on top of the
# squash-merged branch. Such a branch must never be detected as squash-merged.
# Leaves the main branch checked out.
__add_divergent_branch() {
  local main_branch
  main_branch="$(git -C "${repo_dir}" branch --show-current)"

  git -C "${repo_dir}" checkout -b 'divergent-feature' 'squashed-feature'
  echo 'unmerged work' >>"${repo_dir}/feature.txt"
  git -C "${repo_dir}" add feature.txt
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'unmerged work'

  git -C "${repo_dir}" checkout "${main_branch}"
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

# bats test_tags=git::prune::branches::local
@test "git::prune::branches::local force-removes squash-merged branches" {
  local repo_dir

  __create_repo_with_squash_merged_branch
  cd "${repo_dir}"

  # The branch exists and is not an ancestor of main (safe -d would refuse it).
  git branch | grep -q 'squashed-feature'
  ! git branch --merged | grep -q 'squashed-feature'

  run git::prune::branches::local 1
  assert_success

  # Squash-merged branch should be force-deleted.
  ! git branch | grep -q 'squashed-feature'
}

# bats test_tags=git::prune::branches::local
@test "git::prune::branches::local prompt path keeps squash-merged branch on 'no'" {
  local repo_dir

  __create_repo_with_squash_merged_branch
  cd "${repo_dir}"

  # force=0 takes the prompt path; declining must preserve the branch.
  git::prune::branches::local 0 <<<'n'

  git branch | grep -q 'squashed-feature'
}

# bats test_tags=git::prune::branches::local
@test "git::prune::branches::local prompt path removes squash-merged branch on 'yes'" {
  local repo_dir

  __create_repo_with_squash_merged_branch
  cd "${repo_dir}"

  # force=0 takes the prompt path; confirming force-deletes the branch.
  git::prune::branches::local 0 <<<'y'

  ! git branch | grep -q 'squashed-feature'
}

# bats test_tags=git::prune::branches::local
@test "git::prune::branches::local preserves divergent branches under force" {
  local repo_dir

  __create_repo_with_squash_merged_branch
  __add_divergent_branch
  cd "${repo_dir}"

  run git::prune::branches::local 1
  assert_success

  # A divergent branch carrying real unmerged work must survive even under
  # force (the squash-merged branch's removal is covered separately).
  git branch | grep -q 'divergent-feature'
}

# bats test_tags=git::prune::branches::local
@test "git::prune::branches::local never prunes main branch names" {
  local repo_dir="${BATS_TEST_TMPDIR}/protected"

  git init -b 'main' "${repo_dir}"
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  # 'master' and 'mainline' are ancestry-merged into 'main' but protected.
  git -C "${repo_dir}" branch 'master'
  git -C "${repo_dir}" branch 'mainline'
  cd "${repo_dir}"

  run git::prune::branches::local 1 'main'
  assert_success

  git branch | grep -q 'master'
  git branch | grep -q 'mainline'
  git branch | grep -q 'main'
}

################################################################################
# git::prune::branches::is_squash_merged
################################################################################

# bats test_tags=git::prune::branches::is_squash_merged
@test "git::prune::branches::is_squash_merged detects a squash-merged branch" {
  local repo_dir

  __create_repo_with_squash_merged_branch
  cd "${repo_dir}"

  local main_branch
  main_branch="$(git branch --show-current)"

  run git::prune::branches::is_squash_merged "${main_branch}" 'squashed-feature'
  assert_success
}

# bats test_tags=git::prune::branches::is_squash_merged
@test "git::prune::branches::is_squash_merged rejects a divergent branch" {
  local repo_dir

  __create_repo_with_squash_merged_branch
  __add_divergent_branch
  cd "${repo_dir}"

  local main_branch
  main_branch="$(git branch --show-current)"

  run git::prune::branches::is_squash_merged "${main_branch}" 'divergent-feature'
  assert_failure
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
