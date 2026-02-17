#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/worktree.sh'

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

  # Exclude __context__ symlinks from git status
  mkdir -p "${bare_dir}/info"
  echo '__context__' >>"${bare_dir}/info/exclude"

  # Configure remote tracking
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
# git::worktree::default_remote
################################################################################

# bats test_tags=git::worktree::default_remote
@test "git::worktree::default_remote returns origin when config not set" {
  local repo_dir

  __create_cloned_repo

  run git::worktree::default_remote "${repo_dir}"
  assert_success
  assert_output 'origin'
}

# bats test_tags=git::worktree::default_remote
@test "git::worktree::default_remote reads checkout.defaultRemote config" {
  local repo_dir

  __create_cloned_repo
  git -C "${repo_dir}" config checkout.defaultRemote 'upstream'

  run git::worktree::default_remote "${repo_dir}"
  assert_success
  assert_output 'upstream'
}

################################################################################
# git::worktree::previous_file / save_previous / get_previous
################################################################################

# bats test_tags=git::worktree::previous_file
@test "git::worktree::previous_file returns path in git common dir" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::worktree::previous_file
  assert_success
  assert_output --regexp '\.git-friends-previous-worktree$'
}

# bats test_tags=git::worktree::save_previous,git::worktree::get_previous
@test "git::worktree::save_previous and get_previous round-trip" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  git::worktree::save_previous

  run git::worktree::get_previous
  assert_success
  assert_output --regexp '^(main|master)$'
}

# bats test_tags=git::worktree::get_previous
@test "git::worktree::get_previous returns failure when no previous recorded" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::worktree::get_previous
  assert_failure
}

################################################################################
# git::worktree::resolve_branch
################################################################################

# bats test_tags=git::worktree::resolve_branch
@test "git::worktree::resolve_branch passes through regular branch name" {
  run git::worktree::resolve_branch 'feature-branch'
  assert_success
  assert_output 'feature-branch'
}

# bats test_tags=git::worktree::resolve_branch
@test "git::worktree::resolve_branch resolves '-' to previous branch" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  git::worktree::save_previous

  run git::worktree::resolve_branch '-'
  assert_success
  assert_output --regexp '^(main|master)$'
}

# bats test_tags=git::worktree::resolve_branch
@test "git::worktree::resolve_branch fails for '-' with no previous" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::worktree::resolve_branch '-'
  assert_failure
}

################################################################################
# git::worktree::clone
################################################################################

# bats test_tags=git::worktree::clone
@test "git::worktree::clone fails with no repository url" {
  run git::worktree::clone
  assert_failure
}

# bats test_tags=git::worktree::clone
@test "git::worktree::clone fails with invalid repository url" {
  run git::worktree::clone 'not-a-url'
  assert_failure
}

# bats test_tags=git::worktree::clone
@test "git::worktree::clone creates bare worktree structure" {
  local source_dir="${BATS_TEST_TMPDIR}/clone-source"
  local target_dir="${BATS_TEST_TMPDIR}/target"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  run git::worktree::clone "file://${source_dir}" "${target_dir}"
  assert_success

  # Verify bare repo exists
  assert [ -d "${target_dir}/__git__/.git" ]

  # Verify worktree was created for main branch
  local branch
  branch="$(git --git-dir="${target_dir}/__git__/.git" symbolic-ref --short HEAD)"
  assert [ -d "${target_dir}/${branch}" ]
}

# bats test_tags=git::worktree::clone
@test "git::worktree::clone fails when structure already exists" {
  local source_dir="${BATS_TEST_TMPDIR}/clone-source"
  local target_dir="${BATS_TEST_TMPDIR}/target"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  mkdir -p "${target_dir}/__git__"

  run git::worktree::clone "file://${source_dir}" "${target_dir}"
  assert_failure
}

################################################################################
# git::worktree::add::setup
################################################################################

# bats test_tags=git::worktree::add::setup
@test "git::worktree::add::setup sets worktree_dir and worktree_absolute_path" {
  local \
    repo_dir \
    worktree_dir \
    worktree_absolute_path \
    _status=0

  __create_cloned_repo
  cd "${repo_dir}"

  git::worktree::add::setup 'feature' || _status=$?

  assert_equal "${_status}" 0
  assert_equal "${worktree_dir}" '../feature'
  assert_equal "${worktree_absolute_path}" "${BATS_TEST_TMPDIR}/feature"
}

################################################################################
# git::worktree::add::existing
################################################################################

# bats test_tags=git::worktree::add::existing
@test "git::worktree::add::existing fails with no branch" {
  run git::worktree::add::existing
  assert_failure
}

################################################################################
# git::worktree::add::new
################################################################################

# bats test_tags=git::worktree::add::new
@test "git::worktree::add::new fails with no branch" {
  run git::worktree::add::new
  assert_failure
}

# bats test_tags=git::worktree::add::new
@test "git::worktree::add::new creates worktree with new branch" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  run git::worktree::add::new 'feature' "origin/${branch}"
  assert_success
  assert [ -d "${worktree_dir}/feature" ]
}

################################################################################
# git::worktree::add
################################################################################

# bats test_tags=git::worktree::add
@test "git::worktree::add with -b flag routes to add::new" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  run git::worktree::add -b 'new-feature' "origin/${branch}"
  assert_success
  assert [ -d "${worktree_dir}/new-feature" ]
}

################################################################################
# git::worktree::add::existing
################################################################################

# bats test_tags=git::worktree::add::existing
@test "git::worktree::add::existing creates worktree for existing branch" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  # Create a branch in the bare repo to check out
  git branch 'existing-branch'

  run git::worktree::add::existing 'existing-branch'
  assert_success
  assert [ -d "${worktree_dir}/existing-branch" ]
}

# bats test_tags=git::worktree::add::existing
@test "git::worktree::add::existing sets upstream tracking when remote branch exists" {
  local source_dir="${BATS_TEST_TMPDIR}/source"
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  # Create a branch on the source and push it to our bare remote
  git -C "${source_dir}" checkout -b 'remote-feature'
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'feature commit'

  # Fetch so the branch appears as refs/remotes/origin/remote-feature
  git fetch origin

  git::worktree::add::existing 'remote-feature'

  # Verify upstream was set
  local upstream
  upstream="$(git -C "${worktree_dir}/remote-feature" rev-parse --abbrev-ref '@{upstream}')"
  assert_equal "${upstream}" 'origin/remote-feature'
}

################################################################################
# git::worktree::add::setup (duplicate detection)
################################################################################

# bats test_tags=git::worktree::add::setup
@test "git::worktree::add::setup returns 2 for existing worktree" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure

  # Resolve symlinks so PWD matches git worktree list output (macOS /var -> /private/var)
  cd "$(cd "${worktree_dir}/${branch}" && pwd -P)"

  # The main branch worktree already exists
  local \
    worktree_dir_out \
    worktree_absolute_path \
    _status=0

  git::worktree::add::setup "${branch}" || _status=$?

  assert_equal "${_status}" 2
}

################################################################################
# git::worktree::checkout
################################################################################

# bats test_tags=git::worktree::checkout
@test "git::worktree::checkout routes to checkout::existing without -b" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git branch 'checkout-test'

  git::worktree::checkout 'checkout-test'

  assert [ -d "${worktree_dir}/checkout-test" ]
  assert_equal "${PWD}" "${worktree_dir}/checkout-test"
}

# bats test_tags=git::worktree::checkout
@test "git::worktree::checkout routes to checkout::new with -b" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git::worktree::checkout -b 'new-checkout' "origin/${branch}"

  assert [ -d "${worktree_dir}/new-checkout" ]
  assert_equal "${PWD}" "${worktree_dir}/new-checkout"
}

################################################################################
# git::worktree::checkout::existing
################################################################################

# bats test_tags=git::worktree::checkout::existing
@test "git::worktree::checkout::existing fails with no branch" {
  run git::worktree::checkout::existing
  assert_failure
}

# bats test_tags=git::worktree::checkout::existing
@test "git::worktree::checkout::existing creates worktree and changes directory" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git branch 'feature-existing'

  git::worktree::checkout::existing 'feature-existing'

  assert_equal "${PWD}" "${worktree_dir}/feature-existing"
}

# bats test_tags=git::worktree::checkout::existing
@test "git::worktree::checkout::existing saves previous branch" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git branch 'feature-save-prev'

  git::worktree::checkout::existing 'feature-save-prev'

  run git::worktree::get_previous
  assert_success
  assert_output "${branch}"
}

################################################################################
# git::worktree::checkout::new
################################################################################

# bats test_tags=git::worktree::checkout::new
@test "git::worktree::checkout::new fails with no branch" {
  run git::worktree::checkout::new
  assert_failure
}

# bats test_tags=git::worktree::checkout::new
@test "git::worktree::checkout::new creates worktree and changes directory" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git::worktree::checkout::new 'brand-new' "origin/${branch}"

  assert_equal "${PWD}" "${worktree_dir}/brand-new"
}

################################################################################
# git::worktree::clone (additional coverage)
################################################################################

# bats test_tags=git::worktree::clone
@test "git::worktree::clone fails when base directory cannot be created" {
  local source_dir="${BATS_TEST_TMPDIR}/clone-source"
  local readonly_parent="${BATS_TEST_TMPDIR}/readonly"
  local target_dir="${readonly_parent}/nested/target"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  # Create a file where the directory path needs to go
  touch "${readonly_parent}"

  run git::worktree::clone "file://${source_dir}" "${target_dir}"
  assert_failure
}

################################################################################
# git::worktree::add (routing without -b flag)
################################################################################

# bats test_tags=git::worktree::add
@test "git::worktree::add without -b flag routes to add::existing" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git branch 'existing-via-add'

  run git::worktree::add 'existing-via-add'
  assert_success
  assert [ -d "${worktree_dir}/existing-via-add" ]
}

# bats test_tags=git::worktree::add
@test "git::worktree::add with --branch long flag routes to add::new" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  run git::worktree::add --branch 'long-flag-feature' "origin/${branch}"
  assert_success
  assert [ -d "${worktree_dir}/long-flag-feature" ]
}

################################################################################
# git::worktree::add::existing (additional coverage)
################################################################################

# bats test_tags=git::worktree::add::existing
@test "git::worktree::add::existing fails for nonexistent branch" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  run git::worktree::add::existing 'no-such-branch'
  assert_failure
}

################################################################################
# git::worktree::default_remote (no path argument)
################################################################################

# bats test_tags=git::worktree::default_remote
@test "git::worktree::default_remote returns origin with no path argument" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::worktree::default_remote
  assert_success
  assert_output 'origin'
}

# bats test_tags=git::worktree::clone
@test "git::worktree::clone fails when __git__ mkdir fails" {
  local source_dir="${BATS_TEST_TMPDIR}/clone-source"
  local target_dir="${BATS_TEST_TMPDIR}/target"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  # Create base dir but put a file where __git__ dir needs to go
  mkdir -p "${target_dir}"
  touch "${target_dir}/__git__"

  run git::worktree::clone "file://${source_dir}" "${target_dir}"
  assert_failure
}

# bats test_tags=git::worktree::clone
@test "git::worktree::clone fails when bare clone fails" {
  local target_dir="${BATS_TEST_TMPDIR}/clone-fail-target"

  # file:// URL passes is_valid but points to nonexistent repo — fails at git clone --bare
  run git::worktree::clone "file:///tmp/nonexistent-repo-$$" "${target_dir}"
  assert_failure
}

# bats test_tags=git::worktree::clone::cd
@test "git::worktree::clone::cd fails with no arguments" {
  run git::worktree::clone::cd
  assert_failure
}

# bats test_tags=git::worktree::clone::cd
@test "git::worktree::clone::cd fails with invalid URL" {
  run git::worktree::clone::cd 'not-a-valid-url'
  assert_failure
}

# bats test_tags=git::worktree::checkout
@test "git::worktree::checkout::existing cds to existing worktree without re-adding" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure

  # Resolve symlinks for macOS /var -> /private/var
  cd "$(cd "${worktree_dir}/${branch}" && pwd -P)"

  # The main branch worktree already exists from setup
  git::worktree::checkout::existing "${branch}"

  # Should have cd'd to the existing worktree
  assert_equal "$(pwd -P)" "$(cd "${worktree_dir}/${branch}" && pwd -P)"
}

# bats test_tags=git::worktree::checkout
@test "git::worktree::checkout::existing resolves dash to previous branch" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "$(cd "${worktree_dir}/${branch}" && pwd -P)"

  # Create a second branch so we can switch
  local second_branch="feature-test"
  git branch "${second_branch}"

  # Checkout the second branch to set it as current, then go back
  git::worktree::checkout::existing "${second_branch}"
  git::worktree::checkout::existing "${branch}"

  # Now '-' should resolve to the second branch
  git::worktree::checkout::existing '-'

  assert_equal "$(pwd -P)" "$(cd "${worktree_dir}/${second_branch}" && pwd -P)"
}

################################################################################
# git::worktree::clone (derives directory from URL)
################################################################################

# bats test_tags=git::worktree::clone
@test "git::worktree::clone derives directory from repo name when not provided" {
  local source_dir="${BATS_TEST_TMPDIR}/wt-source"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  cd "${BATS_TEST_TMPDIR}"

  run git::worktree::clone "file://${source_dir}"
  assert_success
  assert [ -d "${BATS_TEST_TMPDIR}/wt-source/__git__/.git" ]
}

################################################################################
# git::worktree::clone::cd (derives directory and cds to main worktree)
################################################################################

# bats test_tags=git::worktree::clone::cd
@test "git::worktree::clone::cd derives directory and cds to main worktree" {
  local source_dir="${BATS_TEST_TMPDIR}/clonecd-source"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  cd "${BATS_TEST_TMPDIR}"

  run git::worktree::clone::cd "file://${source_dir}"
  assert_success
}

################################################################################
# git::worktree::add::new (derives start point from main ref)
################################################################################

# bats test_tags=git::worktree::add::new
@test "git::worktree::add::new derives start point when not provided" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  # Don't provide start_point — function should derive from main ref
  run git::worktree::add::new 'auto-start-feature'
  assert_success
  assert [ -d "${worktree_dir}/auto-start-feature" ]
}

################################################################################
# git::worktree::add::new (returns success for already-existing worktree)
################################################################################

# bats test_tags=git::worktree::add::new
@test "git::worktree::add::new returns success when worktree already exists" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure

  # Resolve symlinks for macOS /var -> /private/var
  cd "$(cd "${worktree_dir}/${branch}" && pwd -P)"

  # The main branch worktree already exists — setup returns 2, function returns 0
  run git::worktree::add::new "${branch}" "origin/${branch}"
  assert_success
}

################################################################################
# git::worktree::checkout::existing (fails for dash with no previous)
################################################################################

# bats test_tags=git::worktree::checkout::existing
@test "git::worktree::checkout::existing fails for dash with no previous worktree" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  run git::worktree::checkout::existing '-'
  assert_failure
}

################################################################################
# git::worktree::checkout::existing (fails when branch does not exist)
################################################################################

# bats test_tags=git::worktree::checkout::existing
@test "git::worktree::checkout::existing fails when branch does not exist" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  run git::worktree::checkout::existing 'nonexistent-branch-xyz'
  assert_failure
}

################################################################################
# git::worktree::checkout::new (fails when add::new fails)
################################################################################

# bats test_tags=git::worktree::checkout::new
@test "git::worktree::checkout::new fails when add::new fails" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  # Stub add::new to fail
  git::worktree::add::new() { return 1; }
  export -f git::worktree::add::new

  run git::worktree::checkout::new 'fail-branch'
  assert_failure
}

################################################################################
# git::worktree::__link_context__
################################################################################

# bats test_tags=git::worktree::__link_context__
@test "git::worktree::__link_context__ creates symlink when context dir exists" {
  local project_dir="${BATS_TEST_TMPDIR}/ctx-project"
  local worktree_path="${project_dir}/main"

  mkdir -p "${project_dir}/__context__" "${worktree_path}"

  run git::worktree::__link_context__ "${worktree_path}"
  assert_success
  assert [ -L "${worktree_path}/__context__" ]
  assert_equal "$(readlink "${worktree_path}/__context__")" "../__context__"
}

# bats test_tags=git::worktree::__link_context__
@test "git::worktree::__link_context__ is no-op when context dir does not exist" {
  local project_dir="${BATS_TEST_TMPDIR}/ctx-project"
  local worktree_path="${project_dir}/main"

  mkdir -p "${worktree_path}"

  run git::worktree::__link_context__ "${worktree_path}"
  assert_success
  assert [ ! -L "${worktree_path}/__context__" ]
}

# bats test_tags=git::worktree::__link_context__
@test "git::worktree::__link_context__ is no-op when symlink already exists" {
  local project_dir="${BATS_TEST_TMPDIR}/ctx-project"
  local worktree_path="${project_dir}/main"

  mkdir -p "${project_dir}/__context__" "${worktree_path}"
  ln -s ../__context__ "${worktree_path}/__context__"

  run git::worktree::__link_context__ "${worktree_path}"
  assert_success
  assert [ -L "${worktree_path}/__context__" ]
  assert_equal "$(readlink "${worktree_path}/__context__")" "../__context__"
}

################################################################################
# git::worktree::init_context
################################################################################

# bats test_tags=git::worktree::init_context
@test "git::worktree::init_context creates __context__ dir and links all worktrees" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure

  # Remove __context__ to simulate a pre-existing project without it
  rm -rf "${worktree_dir}/__context__"
  cd "${worktree_dir}/${branch}"

  # Add a second worktree
  git branch 'link-ctx-branch'
  git worktree add "../link-ctx-branch" 'link-ctx-branch'

  git::worktree::init_context

  assert [ -d "${worktree_dir}/__context__" ]
  assert [ -L "${worktree_dir}/${branch}/__context__" ]
  assert [ -L "${worktree_dir}/link-ctx-branch/__context__" ]
  assert_equal "$(readlink "${worktree_dir}/${branch}/__context__")" "../__context__"
  assert_equal "$(readlink "${worktree_dir}/link-ctx-branch/__context__")" "../__context__"
}

# bats test_tags=git::worktree::init_context
@test "git::worktree::init_context adds __context__ to git exclude" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  # Remove exclude entry to simulate pre-existing project
  grep -vF '__context__' "${bare_dir}/info/exclude" >"${bare_dir}/info/exclude.tmp" || true
  mv "${bare_dir}/info/exclude.tmp" "${bare_dir}/info/exclude"

  git::worktree::init_context

  run grep -Fx '__context__' "${bare_dir}/info/exclude"
  assert_success
}

# bats test_tags=git::worktree::init_context
@test "git::worktree::init_context is idempotent" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  # Already has __context__ dir and exclude from helper — run twice
  git::worktree::init_context
  git::worktree::init_context

  assert [ -L "${worktree_dir}/${branch}/__context__" ]

  # Exclude entry should appear exactly once
  local count
  count="$(grep -cFx '__context__' "${bare_dir}/info/exclude")"
  assert_equal "${count}" 1
}

# bats test_tags=git::worktree::init_context
@test "git::worktree::init_context fails outside a git repo" {
  cd "${BATS_TEST_TMPDIR}"

  run git::worktree::init_context
  assert_failure
}

# bats test_tags=git::worktree::init_context
@test "git::worktree::init_context fails outside bare worktree structure" {
  local repo_dir

  __create_cloned_repo
  cd "${repo_dir}"

  run git::worktree::init_context
  assert_failure
}

# bats test_tags=git::worktree::init_context
@test "git::worktree::init_context works with explicit path argument" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure

  # Remove __context__ and exclude to simulate pre-existing project
  rm -rf "${worktree_dir}/__context__"
  grep -vF '__context__' "${bare_dir}/info/exclude" >"${bare_dir}/info/exclude.tmp" || true
  mv "${bare_dir}/info/exclude.tmp" "${bare_dir}/info/exclude"

  # Call with path instead of cd'ing into worktree
  git::worktree::init_context "${worktree_dir}/${branch}"

  assert [ -d "${worktree_dir}/__context__" ]
  assert [ -L "${worktree_dir}/${branch}/__context__" ]
  run grep -Fx '__context__' "${bare_dir}/info/exclude"
  assert_success
}

# bats test_tags=git::worktree::init_context
@test "git::worktree::init_context does not symlink into __git__" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git::worktree::init_context

  assert [ ! -L "${worktree_dir}/__git__/__context__" ]
}

################################################################################
# git::worktree::clone (__context__ support)
################################################################################

# bats test_tags=git::worktree::clone
@test "git::worktree::clone creates __context__ directory" {
  local source_dir="${BATS_TEST_TMPDIR}/ctx-clone-source"
  local target_dir="${BATS_TEST_TMPDIR}/ctx-clone-target"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  run git::worktree::clone "file://${source_dir}" "${target_dir}"
  assert_success
  assert [ -d "${target_dir}/__context__" ]
}

# bats test_tags=git::worktree::clone
@test "git::worktree::clone symlinks __context__ into main worktree" {
  local source_dir="${BATS_TEST_TMPDIR}/ctx-clone-source"
  local target_dir="${BATS_TEST_TMPDIR}/ctx-clone-target"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  run git::worktree::clone "file://${source_dir}" "${target_dir}"
  assert_success

  local branch
  branch="$(git --git-dir="${target_dir}/__git__/.git" symbolic-ref --short HEAD)"
  assert [ -L "${target_dir}/${branch}/__context__" ]
  assert_equal "$(readlink "${target_dir}/${branch}/__context__")" "../__context__"
}

# bats test_tags=git::worktree::clone
@test "git::worktree::clone adds __context__ to git exclude" {
  local source_dir="${BATS_TEST_TMPDIR}/ctx-clone-source"
  local target_dir="${BATS_TEST_TMPDIR}/ctx-clone-target"

  git init "${source_dir}"
  git -C "${source_dir}" \
    -c user.name=test -c user.email=test \
    commit --allow-empty -m 'initial'

  run git::worktree::clone "file://${source_dir}" "${target_dir}"
  assert_success

  run grep -Fx '__context__' "${target_dir}/__git__/.git/info/exclude"
  assert_success
}

################################################################################
# git::worktree::add::existing (__context__ support)
################################################################################

# bats test_tags=git::worktree::add::existing
@test "git::worktree::add::existing symlinks __context__ into worktree" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  git branch 'ctx-existing-branch'

  run git::worktree::add::existing 'ctx-existing-branch'
  assert_success
  assert [ -L "${worktree_dir}/ctx-existing-branch/__context__" ]
  assert_equal "$(readlink "${worktree_dir}/ctx-existing-branch/__context__")" "../__context__"
}

# bats test_tags=git::worktree::add::existing
@test "git::worktree::add::existing skips context when __context__ dir does not exist" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure

  # Remove __context__ to simulate pre-existing project without init_context
  rm -rf "${worktree_dir}/__context__"
  cd "${worktree_dir}/${branch}"

  git branch 'no-ctx-existing'

  run git::worktree::add::existing 'no-ctx-existing'
  assert_success
  assert [ -d "${worktree_dir}/no-ctx-existing" ]
  assert [ ! -L "${worktree_dir}/no-ctx-existing/__context__" ]
}

################################################################################
# git::worktree::add::new (__context__ support)
################################################################################

# bats test_tags=git::worktree::add::new
@test "git::worktree::add::new symlinks __context__ into worktree" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure
  cd "${worktree_dir}/${branch}"

  run git::worktree::add::new 'ctx-new-branch' "origin/${branch}"
  assert_success
  assert [ -L "${worktree_dir}/ctx-new-branch/__context__" ]
  assert_equal "$(readlink "${worktree_dir}/ctx-new-branch/__context__")" "../__context__"
}

# bats test_tags=git::worktree::add::new
@test "git::worktree::add::new skips context when __context__ dir does not exist" {
  local bare_dir worktree_dir branch

  __create_bare_worktree_structure

  # Remove __context__ to simulate pre-existing project without init_context
  rm -rf "${worktree_dir}/__context__"
  cd "${worktree_dir}/${branch}"

  run git::worktree::add::new 'no-ctx-new' "origin/${branch}"
  assert_success
  assert [ -d "${worktree_dir}/no-ctx-new" ]
  assert [ ! -L "${worktree_dir}/no-ctx-new/__context__" ]
}

################################################################################
# git::worktree::clone (integration — network required)
################################################################################

# bats test_tags=git::worktree::clone,integration,network
@test "git::worktree::clone end-to-end with network repository" {
  local target_dir="${BATS_TEST_TMPDIR}/integration-target"

  run git::worktree::clone 'https://github.com/rbuchss/git-friends.git' "${target_dir}"
  assert_success

  # Verify bare repo exists
  assert [ -d "${target_dir}/__git__/.git" ]

  # Verify worktree was created for main branch
  local branch
  branch="$(git --git-dir="${target_dir}/__git__/.git" symbolic-ref --short HEAD)"
  assert [ -d "${target_dir}/${branch}" ]
}
