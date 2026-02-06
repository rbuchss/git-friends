#!/usr/bin/env bats

load ../test_helper

setup_with_coverage 'git-friends/src/hooks/task_runner.sh'

bats_require_minimum_version 1.5.0

################################################################################
# git::hooks::task_runner::usage
################################################################################

# bats test_tags=git::hooks::task_runner::usage
@test "git::hooks::task_runner::usage outputs help text" {
  run git::hooks::task_runner::usage
  assert_success
  assert_output --regexp 'Usage:'
  assert_output --regexp '--name'
  assert_output --regexp '--block'
  assert_output --regexp '--help'
}

################################################################################
# git::hooks::task_runner
################################################################################

# bats test_tags=git::hooks::task_runner
@test "git::hooks::task_runner --help shows usage" {
  run git::hooks::task_runner --help
  assert_success
  assert_output --regexp 'Usage:'
}

# bats test_tags=git::hooks::task_runner
@test "git::hooks::task_runner -h shows usage" {
  run git::hooks::task_runner -h
  assert_success
  assert_output --regexp 'Usage:'
}

# bats test_tags=git::hooks::task_runner
@test "git::hooks::task_runner fails with invalid option" {
  run git::hooks::task_runner --invalid
  assert_failure
}

################################################################################
# git::hooks::task_runner::body
################################################################################

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body returns success with no tasks" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::hooks::task_runner::body \
    'test-hook' \
    'git::hooks::task_runner::background_block'
  assert_success
}

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body fails with non-executable block" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::hooks::task_runner::body \
    'test-hook' \
    'nonexistent_block_function' \
    'some_task'
  assert_failure
}

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body fails with non-executable task" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::hooks::task_runner::body \
    'test-hook' \
    'git::hooks::task_runner::background_block' \
    'nonexistent_task_function'
  assert_failure
}

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body exits early when disabled" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  git -C "${repo_dir}" config 'git-friends.test-hook.disabled' true
  cd "${repo_dir}"

  run git::hooks::task_runner::body \
    'test-hook' \
    'git::hooks::task_runner::background_block' \
    'some_task'
  assert_success
}

################################################################################
# git::hooks::task_runner (argument parsing)
################################################################################

# bats test_tags=git::hooks::task_runner
@test "git::hooks::task_runner with --name flag" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::hooks::task_runner --name 'test-hook'
  assert_success
}

# bats test_tags=git::hooks::task_runner
@test "git::hooks::task_runner with positional name" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run git::hooks::task_runner 'test-hook'
  assert_success
}

# bats test_tags=git::hooks::task_runner
@test "git::hooks::task_runner with --block flag" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  __custom_block() { local task="$1"; "${task}"; }
  export -f __custom_block

  __my_task() { echo "ran"; }
  export -f __my_task

  run git::hooks::task_runner \
    --name 'test-hook' \
    --block '__custom_block' \
    '__my_task'
  assert_success
}

################################################################################
# git::hooks::task_runner::body (with tasks)
################################################################################

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body runs executable tasks" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  __test_task() { echo "task completed"; }
  export -f __test_task

  __simple_block() {
    local task="$1"
    "${task}"
  }
  export -f __simple_block

  run git::hooks::task_runner::body \
    'test-hook' \
    '__simple_block' \
    '__test_task'
  assert_success
}

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body reads tasks from config" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  __config_task() { echo "config task ran"; }
  export -f __config_task

  __simple_block() {
    local task="$1"
    "${task}"
  }
  export -f __simple_block

  git config 'git-friends.test-hook.task' '__config_task'

  run git::hooks::task_runner::body \
    'test-hook' \
    '__simple_block'
  assert_success
}

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body reads skip list from config" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  __skippable_task() { echo "should be skipped"; }
  export -f __skippable_task

  git config 'git-friends.test-hook.skip' '__skippable_task'

  run git::hooks::task_runner::body \
    'test-hook' \
    'git::hooks::task_runner::background_block' \
    '__skippable_task'
  assert_success
}

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body enables logging when configured" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  __log_task() { echo "logged task"; }
  export -f __log_task

  __simple_block() {
    local task="$1"
    "${task}"
  }
  export -f __simple_block

  git config 'git-friends.test-hook.log' 'true'

  run git::hooks::task_runner::body \
    'test-hook' \
    '__simple_block' \
    '__log_task'
  assert_success
}

################################################################################
# git::hooks::task_runner (positional tasks routing through to body)
################################################################################

# bats test_tags=git::hooks::task_runner
@test "git::hooks::task_runner with positional name and tasks calls body" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  __positional_task() { echo "positional task ran"; }
  export -f __positional_task

  __simple_block() {
    local task="$1"
    "${task}"
  }
  export -f __simple_block

  run git::hooks::task_runner \
    --block '__simple_block' \
    'test-hook' \
    '__positional_task'
  assert_success
  assert_output --partial 'positional task ran'
}

################################################################################
# git::hooks::task_runner::body (logging paths)
################################################################################

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body creates log directory when logging enabled" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  __logged_task() { echo "logged output"; }
  export -f __logged_task

  __simple_block() {
    local task="$1"
    "${task}"
  }
  export -f __simple_block

  git config 'git-friends.test-hook.log' 'true'

  run git::hooks::task_runner::body \
    'test-hook' \
    '__simple_block' \
    '__logged_task'
  assert_success

  # Log directory should have been created
  local log_dir
  log_dir="$(git rev-parse --git-dir)/git-friends/logs"
  assert [ -d "${log_dir}" ]
}

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body logs non-executable block error to stderr" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  git config 'git-friends.test-hook.log' 'true'

  run --separate-stderr git::hooks::task_runner::body \
    'test-hook' \
    'nonexistent_block_function' \
    'some_task'
  assert_failure
  assert_stderr --partial 'NO command or function name'
}

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body logs no-tasks info to stderr" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run --separate-stderr git::hooks::task_runner::body \
    'test-hook' \
    'git::hooks::task_runner::background_block'
  assert_success
  assert_stderr --partial 'no tasks to run'
}

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body logs non-executable task error to stderr" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  run --separate-stderr git::hooks::task_runner::body \
    'test-hook' \
    'git::hooks::task_runner::background_block' \
    'nonexistent_task_function'
  assert_failure
  assert_stderr --partial 'NO command or function named'
}

# bats test_tags=git::hooks::task_runner::body
@test "git::hooks::task_runner::body fails when log directory cannot be created" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"
  cd "${repo_dir}"

  git config 'git-friends.test-hook.log' 'true'

  # Create a file where the log directory would go to block mkdir
  local git_dir
  git_dir="$(git rev-parse --git-dir)"
  mkdir -p "${git_dir}/git-friends"
  touch "${git_dir}/git-friends/logs"

  run git::hooks::task_runner::body \
    'test-hook' \
    'git::hooks::task_runner::background_block' \
    'some_task'
  assert_failure
}

################################################################################
# git::hooks::task_runner::background_block
################################################################################

# bats test_tags=git::hooks::task_runner::background_block
@test "git::hooks::task_runner::background_block skips task in skip list" {
  __skipped_task() { echo "should not run"; }
  export -f __skipped_task

  run git::hooks::task_runner::background_block \
    '__skipped_task' \
    '/dev/null' \
    '__skipped_task'
  assert_success
}

# bats test_tags=git::hooks::task_runner::background_block
@test "git::hooks::task_runner::background_block runs task not in skip list" {
  __running_task() { echo "task output"; }
  export -f __running_task

  run git::hooks::task_runner::background_block \
    '__running_task' \
    '/dev/null'
  assert_success
}

# bats test_tags=git::hooks::task_runner::background_block
@test "git::hooks::task_runner::background_block logs INFO for successful task" {
  local logfile="${BATS_TEST_TMPDIR}/bg_block.log"

  __success_task() { echo "success output"; }
  export -f __success_task

  git::hooks::task_runner::background_block \
    '__success_task' \
    "${logfile}"

  # Wait for background job to complete
  wait

  run cat "${logfile}"
  assert_success
  assert_output --regexp 'INFO'
  assert_output --regexp '__success_task'
}

# bats test_tags=git::hooks::task_runner::background_block
@test "git::hooks::task_runner::background_block logs ERROR for failed task" {
  local logfile="${BATS_TEST_TMPDIR}/bg_block_fail.log"

  __fail_task() { echo "fail output"; return 1; }
  export -f __fail_task

  git::hooks::task_runner::background_block \
    '__fail_task' \
    "${logfile}"

  # Wait for background job to complete
  wait

  run cat "${logfile}"
  assert_success
  assert_output --regexp 'ERROR'
  assert_output --regexp '__fail_task'
}

# bats test_tags=git::hooks::task_runner::background_block
@test "git::hooks::task_runner::background_block logs warning for skipped task" {
  __skip_target() { echo "should not run"; }
  export -f __skip_target

  run --separate-stderr git::hooks::task_runner::background_block \
    '__skip_target' \
    '/dev/null' \
    '__skip_target'
  assert_success
  assert_stderr --partial 'skipped __skip_target'
}
