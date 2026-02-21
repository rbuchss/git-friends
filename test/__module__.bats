#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/__module__.sh'

bats_require_minimum_version 1.5.0

################################################################################
# git::__module__::__function_exists__
################################################################################

# bats test_tags=git::__module__,git::__module__::__function_exists__
@test "git::__module__::__function_exists__ with-existing-function" {
  run git::__module__::__function_exists__ 'git::__module__::load'

  assert_success
}

# bats test_tags=git::__module__,git::__module__::__function_exists__
@test "git::__module__::__function_exists__ with-nonexistent-function" {
  run git::__module__::__function_exists__ 'nonexistent::function::name'

  assert_failure
}

################################################################################
# git::__module__::__invoke_function_if_exists__
################################################################################

# bats test_tags=git::__module__,git::__module__::__invoke_function_if_exists__
@test "git::__module__::__invoke_function_if_exists__ with-existing-function" {
  # shellcheck disable=SC2317 # invoked indirectly
  __test_helper_func__() { echo 'invoked'; }

  run git::__module__::__invoke_function_if_exists__ '__test_helper_func__'

  assert_success
  assert_output 'invoked'

  unset -f __test_helper_func__
}

# bats test_tags=git::__module__,git::__module__::__invoke_function_if_exists__
@test "git::__module__::__invoke_function_if_exists__ with-nonexistent-function" {
  run git::__module__::__invoke_function_if_exists__ 'nonexistent_function_12345'

  assert_success
  assert_output ''
}

# bats test_tags=git::__module__,git::__module__::__invoke_function_if_exists__
@test "git::__module__::__invoke_function_if_exists__ passes-arguments" {
  # shellcheck disable=SC2317 # invoked indirectly
  __test_args_func__() { echo "args: $*"; }

  run git::__module__::__invoke_function_if_exists__ '__test_args_func__' 'a' 'b' 'c'

  assert_success
  assert_output 'args: a b c'

  unset -f __test_args_func__
}

################################################################################
# git::__module__::__action__
################################################################################

# bats test_tags=git::__module__,git::__module__::__action__
@test "git::__module__::__action__ with-invalid-action" {
  run git::__module__::__action__ 'test_module' 'invalid_action'

  assert_failure 2
}

# bats test_tags=git::__module__,git::__module__::__action__
@test "git::__module__::__action__ with-valid-load-action" {
  # Reset loaded modules for this test
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=()

  run git::__module__::__action__ '__test_module_action__' '__load__'

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")

  assert_success
}

# bats test_tags=git::__module__,git::__module__::__action__
@test "git::__module__::__action__ already-in-state" {
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=('__test_already_loaded__')

  run git::__module__::__action__ '__test_already_loaded__' '__load__'

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")

  # Returns 1 when module is already in the desired state
  assert_failure 1
}

################################################################################
# git::__module__::__is_in_state__
################################################################################

# bats test_tags=git::__module__,git::__module__::__is_in_state__
@test "git::__module__::__is_in_state__ loaded-module" {
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=('test_module_a' 'test_module_b')

  run git::__module__::__is_in_state__ 'test_module_a' '__load__'

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")

  assert_success
}

# bats test_tags=git::__module__,git::__module__::__is_in_state__
@test "git::__module__::__is_in_state__ not-loaded-module" {
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=('test_module_a')

  run git::__module__::__is_in_state__ 'test_module_not_loaded' '__load__'

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")

  assert_failure
}

# bats test_tags=git::__module__,git::__module__::__is_in_state__
@test "git::__module__::__is_in_state__ unload-when-loaded" {
  # For unload action, in_cache means NOT in desired state (inverted logic)
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=('test_module_a')

  run git::__module__::__is_in_state__ 'test_module_a' '__unload__'

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")

  # Module is loaded, so it's NOT in "unloaded" state
  assert_failure
}

# bats test_tags=git::__module__,git::__module__::__is_in_state__
@test "git::__module__::__is_in_state__ unload-when-not-loaded" {
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=()

  run git::__module__::__is_in_state__ 'test_module_a' '__unload__'

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")

  # Module is not loaded, so it IS in "unloaded" state
  assert_success
}

# bats test_tags=git::__module__,git::__module__::__is_in_state__
@test "git::__module__::__is_in_state__ exported-module" {
  local original_exported=("${GIT_FRIENDS_MODULES_EXPORTED[@]}")
  GIT_FRIENDS_MODULES_EXPORTED=('test_module_a')

  run git::__module__::__is_in_state__ 'test_module_a' '__export__'

  GIT_FRIENDS_MODULES_EXPORTED=("${original_exported[@]}")

  assert_success
}

# bats test_tags=git::__module__,git::__module__::__is_in_state__
@test "git::__module__::__is_in_state__ recall-when-exported" {
  local original_exported=("${GIT_FRIENDS_MODULES_EXPORTED[@]}")
  GIT_FRIENDS_MODULES_EXPORTED=('test_module_a')

  run git::__module__::__is_in_state__ 'test_module_a' '__recall__'

  GIT_FRIENDS_MODULES_EXPORTED=("${original_exported[@]}")

  # Module is exported, so it's NOT in "recalled" state
  assert_failure
}

# bats test_tags=git::__module__,git::__module__::__is_in_state__
@test "git::__module__::__is_in_state__ enabled-module" {
  local original_enabled=("${GIT_FRIENDS_MODULES_ENABLED[@]}")
  GIT_FRIENDS_MODULES_ENABLED=('test_module_a')

  run git::__module__::__is_in_state__ 'test_module_a' '__enable__'

  GIT_FRIENDS_MODULES_ENABLED=("${original_enabled[@]}")

  assert_success
}

# bats test_tags=git::__module__,git::__module__::__is_in_state__
@test "git::__module__::__is_in_state__ disable-when-enabled" {
  local original_enabled=("${GIT_FRIENDS_MODULES_ENABLED[@]}")
  GIT_FRIENDS_MODULES_ENABLED=('test_module_a')

  run git::__module__::__is_in_state__ 'test_module_a' '__disable__'

  GIT_FRIENDS_MODULES_ENABLED=("${original_enabled[@]}")

  assert_failure
}

# bats test_tags=git::__module__,git::__module__::__is_in_state__
@test "git::__module__::__is_in_state__ invalid-action" {
  run git::__module__::__is_in_state__ 'test_module' 'invalid_action'

  assert_failure 2
}

################################################################################
# git::__module__::is_loaded / is_unloaded
################################################################################

# bats test_tags=git::__module__,git::__module__::is_loaded
@test "git::__module__::is_loaded with-loaded-module" {
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=('test_module_check')

  run git::__module__::is_loaded 'test_module_check'

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")

  assert_success
}

# bats test_tags=git::__module__,git::__module__::is_loaded
@test "git::__module__::is_loaded with-not-loaded-module" {
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=()

  run git::__module__::is_loaded 'test_module_check'

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")

  assert_failure
}

# bats test_tags=git::__module__,git::__module__::is_unloaded
@test "git::__module__::is_unloaded with-not-loaded-module" {
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=()

  run git::__module__::is_unloaded 'test_module_check'

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")

  assert_success
}

# bats test_tags=git::__module__,git::__module__::is_unloaded
@test "git::__module__::is_unloaded with-loaded-module" {
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=('test_module_check')

  run git::__module__::is_unloaded 'test_module_check'

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")

  assert_failure
}

################################################################################
# git::__module__::is_exported / is_recalled
################################################################################

# bats test_tags=git::__module__,git::__module__::is_exported
@test "git::__module__::is_exported with-exported-module" {
  local original_exported=("${GIT_FRIENDS_MODULES_EXPORTED[@]}")
  GIT_FRIENDS_MODULES_EXPORTED=('test_module_exp')

  run git::__module__::is_exported 'test_module_exp'

  GIT_FRIENDS_MODULES_EXPORTED=("${original_exported[@]}")

  assert_success
}

# bats test_tags=git::__module__,git::__module__::is_exported
@test "git::__module__::is_exported with-not-exported-module" {
  local original_exported=("${GIT_FRIENDS_MODULES_EXPORTED[@]}")
  GIT_FRIENDS_MODULES_EXPORTED=()

  run git::__module__::is_exported 'test_module_exp'

  GIT_FRIENDS_MODULES_EXPORTED=("${original_exported[@]}")

  assert_failure
}

# bats test_tags=git::__module__,git::__module__::is_recalled
@test "git::__module__::is_recalled with-not-exported-module" {
  local original_exported=("${GIT_FRIENDS_MODULES_EXPORTED[@]}")
  GIT_FRIENDS_MODULES_EXPORTED=()

  run git::__module__::is_recalled 'test_module_exp'

  GIT_FRIENDS_MODULES_EXPORTED=("${original_exported[@]}")

  assert_success
}

# bats test_tags=git::__module__,git::__module__::is_recalled
@test "git::__module__::is_recalled with-exported-module" {
  local original_exported=("${GIT_FRIENDS_MODULES_EXPORTED[@]}")
  GIT_FRIENDS_MODULES_EXPORTED=('test_module_exp')

  run git::__module__::is_recalled 'test_module_exp'

  GIT_FRIENDS_MODULES_EXPORTED=("${original_exported[@]}")

  assert_failure
}

################################################################################
# git::__module__::is_enabled / is_disabled
################################################################################

# bats test_tags=git::__module__,git::__module__::is_enabled
@test "git::__module__::is_enabled with-enabled-module" {
  local original_enabled=("${GIT_FRIENDS_MODULES_ENABLED[@]}")
  GIT_FRIENDS_MODULES_ENABLED=('test_module_en')

  run git::__module__::is_enabled 'test_module_en'

  GIT_FRIENDS_MODULES_ENABLED=("${original_enabled[@]}")

  assert_success
}

# bats test_tags=git::__module__,git::__module__::is_enabled
@test "git::__module__::is_enabled with-not-enabled-module" {
  local original_enabled=("${GIT_FRIENDS_MODULES_ENABLED[@]}")
  GIT_FRIENDS_MODULES_ENABLED=()

  run git::__module__::is_enabled 'test_module_en'

  GIT_FRIENDS_MODULES_ENABLED=("${original_enabled[@]}")

  assert_failure
}

# bats test_tags=git::__module__,git::__module__::is_disabled
@test "git::__module__::is_disabled with-not-enabled-module" {
  local original_enabled=("${GIT_FRIENDS_MODULES_ENABLED[@]}")
  GIT_FRIENDS_MODULES_ENABLED=()

  run git::__module__::is_disabled 'test_module_en'

  GIT_FRIENDS_MODULES_ENABLED=("${original_enabled[@]}")

  assert_success
}

# bats test_tags=git::__module__,git::__module__::is_disabled
@test "git::__module__::is_disabled with-enabled-module" {
  local original_enabled=("${GIT_FRIENDS_MODULES_ENABLED[@]}")
  GIT_FRIENDS_MODULES_ENABLED=('test_module_en')

  run git::__module__::is_disabled 'test_module_en'

  GIT_FRIENDS_MODULES_ENABLED=("${original_enabled[@]}")

  assert_failure
}

################################################################################
# git::__module__::__get_module_name__
################################################################################

# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ with-empty-caller" {
  local result=''

  run git::__module__::__get_module_name__ result ''

  assert_failure
}

# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ with-NULL-caller" {
  local result=''

  run git::__module__::__get_module_name__ result '1 NULL'

  assert_failure
}

# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ derives git::cd from cd.sh" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/path/to'

  git::__module__::__get_module_name__ result '1 /path/to/git-friends/src/cd.sh'

  assert_equal "${result}" 'git::cd'
}

# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ derives git::logger from logger.sh" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/path/to'

  git::__module__::__get_module_name__ result '1 /path/to/git-friends/src/logger.sh'

  assert_equal "${result}" 'git::logger'
}

# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ derives git::exec from exec.sh" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/path/to'

  git::__module__::__get_module_name__ result '1 /path/to/git-friends/src/exec.sh'

  assert_equal "${result}" 'git::exec'
}

# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ derives git::hooks::post_commit from hooks/post_commit.sh" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/path/to'

  git::__module__::__get_module_name__ result '1 /path/to/git-friends/src/hooks/post_commit.sh'

  assert_equal "${result}" 'git::hooks::post_commit'
}

# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ derives git::hooks::task_runner from hooks/task_runner.sh" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/path/to'

  git::__module__::__get_module_name__ result '1 /path/to/git-friends/src/hooks/task_runner.sh'

  assert_equal "${result}" 'git::hooks::task_runner'
}

# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ derives git::completion from completion.sh" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/path/to'

  git::__module__::__get_module_name__ result '1 /path/to/git-friends/src/completion.sh'

  assert_equal "${result}" 'git::completion'
}

# Edge case: dot-prefixed .git-friends symlink path (homesick installs to ~/.git-friends)
# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ handles .git-friends symlink path" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/Users/russ'

  git::__module__::__get_module_name__ result '1 /Users/russ/.git-friends/src/logger.sh'

  assert_equal "${result}" 'git::logger'
}

# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ handles .git-friends symlink path for hooks" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/Users/russ'

  git::__module__::__get_module_name__ result '1 /Users/russ/.git-friends/src/hooks/post_commit.sh'

  assert_equal "${result}" 'git::hooks::post_commit'
}

# Edge case: real path through .homesick/repos
# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ handles .homesick real path" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/Users/russ/.homesick/repos/git-friends'

  git::__module__::__get_module_name__ result '1 /Users/russ/.homesick/repos/git-friends/git-friends/src/cd.sh'

  assert_equal "${result}" 'git::cd'
}

# Edge case: Docker/CI path
# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ handles Docker workspace path" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/workspace'

  git::__module__::__get_module_name__ result '1 /workspace/git-friends/src/worktree.sh'

  assert_equal "${result}" 'git::worktree'
}

# Edge case: preserves underscores in filenames (post_commit should NOT become post::commit)
# bats test_tags=git::__module__,git::__module__::__get_module_name__
@test "git::__module__::__get_module_name__ preserves underscores in filenames" {
  local result=''
  GIT_FRIENDS_MODULE_HOME_DIR='/Users/russ'

  git::__module__::__get_module_name__ result '1 /Users/russ/.git-friends/src/hooks/pre_commit.sh'

  assert_equal "${result}" 'git::hooks::pre_commit'
}

################################################################################
# Integration: source guard prevents double-load
################################################################################

# bats test_tags=git::__module__,integration
@test "git::__module__::load prevents double-load" {
  local original_loaded=("${GIT_FRIENDS_MODULES_LOADED[@]}")
  GIT_FRIENDS_MODULES_LOADED=()

  # First load should succeed
  run git::__module__::load 'test::double_load'
  assert_success

  # Add to loaded array (normally done by load function but run uses subshell)
  GIT_FRIENDS_MODULES_LOADED=('test::double_load')

  # Second load should fail (already loaded)
  run git::__module__::load 'test::double_load'
  assert_failure

  GIT_FRIENDS_MODULES_LOADED=("${original_loaded[@]}")
}

################################################################################
# Integration: enable/disable lifecycle dispatch
################################################################################

# bats test_tags=git::__module__,integration
@test "git::__module__::enable dispatches to __enable__ function" {
  local original_enabled=("${GIT_FRIENDS_MODULES_ENABLED[@]}")
  GIT_FRIENDS_MODULES_ENABLED=()
  local enable_called=0

  # shellcheck disable=SC2317 # invoked indirectly
  test::lifecycle::__enable__() { enable_called=1; }
  export -f test::lifecycle::__enable__

  git::__module__::enable 'test::lifecycle'

  assert_equal "${enable_called}" 1

  unset -f test::lifecycle::__enable__
  GIT_FRIENDS_MODULES_ENABLED=("${original_enabled[@]}")
}

# bats test_tags=git::__module__,integration
@test "git::__module__::disable dispatches to __disable__ function" {
  local original_enabled=("${GIT_FRIENDS_MODULES_ENABLED[@]}")
  GIT_FRIENDS_MODULES_ENABLED=('test::lifecycle')
  local disable_called=0

  # shellcheck disable=SC2317 # invoked indirectly
  test::lifecycle::__disable__() { disable_called=1; }
  export -f test::lifecycle::__disable__

  git::__module__::disable 'test::lifecycle'

  assert_equal "${disable_called}" 1

  unset -f test::lifecycle::__disable__
  GIT_FRIENDS_MODULES_ENABLED=("${original_enabled[@]}")
}

################################################################################
# Integration: export/recall lifecycle dispatch
################################################################################

# bats test_tags=git::__module__,integration
@test "git::__module__::export dispatches to __export__ function" {
  local original_exported=("${GIT_FRIENDS_MODULES_EXPORTED[@]}")
  GIT_FRIENDS_MODULES_EXPORTED=()
  local export_called=0

  # shellcheck disable=SC2317 # invoked indirectly
  test::export_lifecycle::__export__() { export_called=1; }
  export -f test::export_lifecycle::__export__

  git::__module__::export 'test::export_lifecycle'

  assert_equal "${export_called}" 1

  unset -f test::export_lifecycle::__export__
  GIT_FRIENDS_MODULES_EXPORTED=("${original_exported[@]}")
}

# bats test_tags=git::__module__,integration
@test "git::__module__::recall dispatches to __recall__ function" {
  local original_exported=("${GIT_FRIENDS_MODULES_EXPORTED[@]}")
  GIT_FRIENDS_MODULES_EXPORTED=('test::recall_lifecycle')
  local recall_called=0

  # shellcheck disable=SC2317 # invoked indirectly
  test::recall_lifecycle::__recall__() { recall_called=1; }
  export -f test::recall_lifecycle::__recall__

  git::__module__::recall 'test::recall_lifecycle'

  assert_equal "${recall_called}" 1

  unset -f test::recall_lifecycle::__recall__
  GIT_FRIENDS_MODULES_EXPORTED=("${original_exported[@]}")
}
