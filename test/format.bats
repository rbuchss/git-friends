#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/format.sh'

# Helper to create a repo with files.
# Sets repo_dir in caller's scope.
__create_repo_with_files() {
  repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
}

################################################################################
# git::format::newline::process
################################################################################

# bats test_tags=git::format::newline::process
@test "git::format::newline::process fails with no files" {
  run git::format::newline::process
  assert_failure
}

# bats test_tags=git::format::newline::process
@test "git::format::newline::process adds newline to file missing one" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'no trailing newline' > 'test.txt'

  run git::format::newline::process 'test.txt'
  assert_success

  # Verify file now ends with newline
  local last_byte
  last_byte="$(tail -c1 'test.txt')"
  assert_equal "${last_byte}" ''
}

# bats test_tags=git::format::newline::process
@test "git::format::newline::process skips file already ending with newline" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'has trailing newline\n' > 'test.txt'
  local before_size
  before_size="$(wc -c < 'test.txt')"

  run git::format::newline::process 'test.txt'
  assert_success

  local after_size
  after_size="$(wc -c < 'test.txt')"
  assert_equal "${before_size}" "${after_size}"
}

# bats test_tags=git::format::newline::process
@test "git::format::newline::process skips empty files" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  touch 'empty.txt'

  run git::format::newline::process 'empty.txt'
  assert_success

  # File should still be empty
  assert [ ! -s 'empty.txt' ]
}

# bats test_tags=git::format::newline::process
@test "git::format::newline::process skips symlinks" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'content' > 'real.txt'
  ln -s 'real.txt' 'link.txt'

  run git::format::newline::process 'link.txt'
  assert_success
}

# bats test_tags=git::format::newline::process
@test "git::format::newline::process warns for nonexistent file" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  run git::format::newline::process 'nonexistent.txt'
  assert_failure
}

# bats test_tags=git::format::newline::process
@test "git::format::newline::process handles multiple files" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'file one' > 'a.txt'
  printf 'file two' > 'b.txt'
  printf 'file three\n' > 'c.txt'

  run git::format::newline::process 'a.txt' 'b.txt' 'c.txt'
  assert_success

  # a.txt and b.txt should now have newlines
  assert_equal "$(tail -c1 'a.txt')" ''
  assert_equal "$(tail -c1 'b.txt')" ''
}

################################################################################
# git::format::newline
################################################################################

# bats test_tags=git::format::newline
@test "git::format::newline fails with invalid mode" {
  run git::format::newline 'invalid'
  assert_failure
}

# bats test_tags=git::format::newline
@test "git::format::newline ref mode fails without commit ref" {
  run git::format::newline 'ref'
  assert_failure
}

################################################################################
# git::format::__is_in_submodule__
################################################################################

# bats test_tags=git::format::__is_in_submodule__
@test "git::format::__is_in_submodule__ returns failure when no .gitmodules" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  run git::format::__is_in_submodule__ 'some/file.txt'
  assert_failure
}

################################################################################
# git::format::__newline_from_command__
################################################################################

# bats test_tags=git::format::__newline_from_command__
@test "git::format::__newline_from_command__ fails outside git repo" {
  cd "${BATS_TEST_TMPDIR}"

  run git::format::__newline_from_command__ 'test' echo 'file.txt'
  assert_failure
}

# bats test_tags=git::format::__newline_from_command__
@test "git::format::__newline_from_command__ handles empty file list" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  # Using true which produces no output
  run git::format::__newline_from_command__ 'test' true
  assert_success
}

# bats test_tags=git::format::__newline_from_command__
@test "git::format::__newline_from_command__ processes files from command output" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'no newline' > 'a.txt'
  git add 'a.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'add file'

  # Use git ls-files which will list a.txt
  run git::format::__newline_from_command__ 'tracked' git ls-files
  assert_success

  # Verify file now ends with newline
  assert_equal "$(tail -c1 'a.txt')" ''
}

################################################################################
# git::format::newline (mode dispatch)
################################################################################

# bats test_tags=git::format::newline
@test "git::format::newline 'all' processes tracked files" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'content' > 'tracked.txt'
  git add 'tracked.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'add file'

  run git::format::newline 'all'
  assert_success

  assert_equal "$(tail -c1 'tracked.txt')" ''
}

# bats test_tags=git::format::newline
@test "git::format::newline 'tracked' is alias for all" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'content' > 'tracked.txt'
  git add 'tracked.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'add file'

  run git::format::newline 'tracked'
  assert_success
}

# bats test_tags=git::format::newline
@test "git::format::newline 'staged' processes staged files" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  # Create an initial commit so HEAD exists
  printf 'initial\n' > 'init.txt'
  git add 'init.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'initial'

  # Stage a file missing newline
  printf 'no newline' > 'staged.txt'
  git add 'staged.txt'

  run git::format::newline 'staged'
  assert_success

  assert_equal "$(tail -c1 'staged.txt')" ''
}

# bats test_tags=git::format::newline
@test "git::format::newline 'dc' is alias for staged" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'initial\n' > 'init.txt'
  git add 'init.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'initial'

  printf 'no newline' > 'staged.txt'
  git add 'staged.txt'

  run git::format::newline 'dc'
  assert_success
}

# bats test_tags=git::format::newline
@test "git::format::newline 'changed' processes modified files" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'initial\n' > 'file.txt'
  git add 'file.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'initial'

  # Modify file without staging
  printf 'modified' > 'file.txt'

  run git::format::newline 'changed'
  assert_success

  assert_equal "$(tail -c1 'file.txt')" ''
}

# bats test_tags=git::format::newline
@test "git::format::newline 'ref' processes files changed against ref" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'initial\n' > 'file.txt'
  git add 'file.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'initial'

  printf 'changed' > 'file.txt'
  git add 'file.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'changed'

  run git::format::newline 'ref' 'HEAD^'
  assert_success

  assert_equal "$(tail -c1 'file.txt')" ''
}

################################################################################
# git::format::newline::process (additional edge cases)
################################################################################

# bats test_tags=git::format::newline::process
@test "git::format::newline::process fails for unreadable file" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'content' > 'unreadable.txt'
  chmod 000 'unreadable.txt'

  run git::format::newline::process 'unreadable.txt'
  assert_failure

  chmod 644 'unreadable.txt'
}

# bats test_tags=git::format::newline::process
@test "git::format::newline::process fails for unwritable file" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'content' > 'readonly.txt'
  chmod 444 'readonly.txt'

  run git::format::newline::process 'readonly.txt'
  assert_failure

  chmod 644 'readonly.txt'
}

################################################################################
# git::format::__is_in_submodule__ (match cases)
################################################################################

# bats test_tags=git::format::__is_in_submodule__
@test "git::format::__is_in_submodule__ detects file in submodule path" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  cat > '.gitmodules' <<'GITMODULES'
[submodule "vendor/lib"]
  path = vendor/lib
  url = https://example.com/lib.git
GITMODULES

  run git::format::__is_in_submodule__ 'vendor/lib/src/main.c'
  assert_success
}

# bats test_tags=git::format::__is_in_submodule__
@test "git::format::__is_in_submodule__ detects exact submodule path" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  cat > '.gitmodules' <<'GITMODULES'
[submodule "vendor/lib"]
  path = vendor/lib
  url = https://example.com/lib.git
GITMODULES

  run git::format::__is_in_submodule__ 'vendor/lib'
  assert_success
}

# bats test_tags=git::format::newline::process
@test "git::format::newline::process skips submodule files" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  cat > '.gitmodules' <<'GITMODULES'
[submodule "vendor/lib"]
  path = vendor/lib
  url = https://example.com/lib.git
GITMODULES

  mkdir -p 'vendor/lib'
  printf 'content' > 'vendor/lib/file.txt'

  run git::format::newline::process 'vendor/lib/file.txt'
  assert_success
}

# bats test_tags=git::format::newline
@test "git::format::newline 'df' is alias for changed" {
  local repo_dir

  __create_repo_with_files
  cd "${repo_dir}"

  printf 'initial\n' > 'file.txt'
  git add 'file.txt'
  git -c user.name=test -c user.email=test \
    commit -m 'initial'

  printf 'modified' > 'file.txt'

  run git::format::newline 'df'
  assert_success
}

# bats test_tags=git::format::newline::process
@test "git::format::newline::process leaves symlink target unchanged" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"
  git init "${repo_dir}"
  cd "${repo_dir}"

  printf 'target content' > 'target.txt'
  ln -s 'target.txt' 'link.txt'

  run git::format::newline::process 'link.txt'
  assert_success

  # The target file should NOT have been modified (symlink was skipped)
  [[ "$(tail -c1 'target.txt')" != "" ]]
}

