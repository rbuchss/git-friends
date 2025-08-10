#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/logger.sh'

bats_require_minimum_version 1.5.0

# NOTE that any common envs used in these tests must be standard env vars and not readonly.
# Readonly does not get properly exported to the tests making these vars null.
ISO_8601_TIMESTAMP_PATTERN='[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(Z|[+-][0-9]{4})'

LOG_MESSAGES=(
  'Twas brillig, and the slithy toves'
  'Did gyre and gimble in the wabe;'
  'All mimsy were the borogoves,'
  'And the mome raths outgrab'
)

################################################################################
# section: git::logger::trace
################################################################################

# bats test_tags=git::logger,git::logger::trace,output_stderr
@test "git::logger::trace" {
  run --separate-stderr \
    git::logger::trace \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::trace,output_stderr
@test "git::logger::trace level_override=trace" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='trace'

  run --separate-stderr \
    git::logger::trace \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^T, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   TRACE -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::trace,output_stderr
@test "git::logger::trace level_override=debug" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='debug'

  run --separate-stderr \
    git::logger::trace \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::trace,output_stderr
@test "git::logger::trace silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::trace \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: git::logger::debug
################################################################################

# bats test_tags=git::logger,git::logger::debug,output_stderr
@test "git::logger::debug" {
  run --separate-stderr \
    git::logger::debug \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::debug,output_stderr
@test "git::logger::debug level_override=debug" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='debug'

  run --separate-stderr \
    git::logger::debug \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^D, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   DEBUG -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::debug,output_stderr
@test "git::logger::debug level_override=info" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='info'

  run --separate-stderr \
    git::logger::debug \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::debug,output_stderr
@test "git::logger::debug silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::debug \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: git::logger::info
################################################################################

# bats test_tags=git::logger,git::logger::info,output_stderr
@test "git::logger::info" {
  local _message

  run --separate-stderr \
    git::logger::info \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '    INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::info,output_stderr
@test "git::logger::info level_override=info" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='info'

  run --separate-stderr \
    git::logger::info \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::info,output_stderr
@test "git::logger::info level_override=warning" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='warning'

  run --separate-stderr \
    git::logger::info \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::info,output_stderr
@test "git::logger::info silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::info \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: git::logger::warning
################################################################################

# bats test_tags=git::logger,git::logger::warning,output_stderr
@test "git::logger::warning" {
  local _message

  run --separate-stderr \
    git::logger::warning \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^W, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp ' WARNING -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::warning,output_stderr
@test "git::logger::warning level_override=warning" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='warning'

  run --separate-stderr \
    git::logger::warning \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^W, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp ' WARNING -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::warning,output_stderr
@test "git::logger::warning level_override=error" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='error'

  run --separate-stderr \
    git::logger::warning \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::warning,output_stderr
@test "git::logger::warning silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::warning \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: git::logger::error
################################################################################

# bats test_tags=git::logger,git::logger::error,output_stderr
@test "git::logger::error" {
  local _message

  run --separate-stderr \
    git::logger::error \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^E, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   ERROR -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::error,output_stderr
@test "git::logger::error level_override=error" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='error'

  run --separate-stderr \
    git::logger::error \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^E, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   ERROR -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::error,output_stderr
@test "git::logger::error level_override=fatal" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='fatal'

  run --separate-stderr \
    git::logger::error \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::error,output_stderr
@test "git::logger::error silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::error \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: git::logger::fatal
################################################################################

# bats test_tags=git::logger,git::logger::fatal,output_stderr
@test "git::logger::fatal" {
  local _message

  run --separate-stderr \
    git::logger::fatal \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^F, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   FATAL -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done

  assert_stderr --regexp '-> Traceback \(most recent call last\):'
}

# bats test_tags=git::logger,git::logger::fatal,output_stderr
@test "git::logger::fatal level_override=fatal" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='fatal'

  run --separate-stderr \
    git::logger::fatal \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^F, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   FATAL -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::fatal,output_stderr
@test "git::logger::fatal silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::fatal \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

################################################################################
# section: git::logger::log
################################################################################

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log" {
  local _message

  run --separate-stderr \
    git::logger::log "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '    INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level trace" {
  run --separate-stderr \
    git::logger::log \
      --level 'trace' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level trace level_override=trace" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='trace'

  run --separate-stderr \
    git::logger::log \
      --level 'trace' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^T, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   TRACE -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level trace level_override=debug" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='debug'

  run --separate-stderr \
    git::logger::log \
      --level 'trace' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level trace silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::log \
      --level 'trace' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level debug" {
  run --separate-stderr \
    git::logger::log \
      --level 'debug' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level debug level_override=debug" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='debug'

  run --separate-stderr \
    git::logger::log \
      --level 'debug' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^D, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   DEBUG -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level debug level_override=info" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='info'

  run --separate-stderr \
    git::logger::log \
      --level 'debug' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level debug silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::log \
      --level 'debug' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level info" {
  local _message

  run --separate-stderr \
    git::logger::log \
      --level 'info' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '    INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level info level_override=info" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='info'

  run --separate-stderr \
    git::logger::log \
      --level 'info' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level info level_override=warning" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='warning'

  run --separate-stderr \
    git::logger::log \
      --level 'info' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level info silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::log \
      --level 'info' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level warning" {
  local _message

  run --separate-stderr \
    git::logger::log \
      --level 'warning' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^W, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp ' WARNING -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level warning level_override=warning" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='warning'

  run --separate-stderr \
    git::logger::log \
      --level 'warning' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^W, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp ' WARNING -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level warning level_override=error" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='error'

  run --separate-stderr \
    git::logger::log \
      --level 'warning' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level warning silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::log \
      --level 'warning' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level error" {
  local _message

  run --separate-stderr \
    git::logger::log \
      --level 'error' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^E, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   ERROR -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level error level_override=error" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='error'

  run --separate-stderr \
    git::logger::log \
      --level 'error' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^E, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   ERROR -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level error level_override=fatal" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='fatal'

  run --separate-stderr \
    git::logger::log \
      --level 'error' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level error silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::log \
      --level 'error' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level fatal" {
  local _message

  run --separate-stderr \
    git::logger::log \
      --level 'fatal' \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^F, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   FATAL -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done

  assert_stderr --regexp '-> Traceback \(most recent call last\):'
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level fatal level_override=fatal" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='fatal'

  run --separate-stderr \
    git::logger::log \
      --level 'fatal' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  refute_output
  assert_stderr --regexp '^F, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   FATAL -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --level fatal silenced" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run --separate-stderr \
    git::logger::log \
      --level 'fatal' \
      "${LOG_MESSAGES[@]}"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  refute_output
  refute_stderr
}

# bats test_tags=git::logger,git::logger::log,output_stdout
@test "git::logger::log --output /dev/stdout" {
  local _message

  run --separate-stderr \
    git::logger::log \
    --output /dev/stdout \
    "${LOG_MESSAGES[@]}"

  assert_success
  refute_stderr
  assert_output --regexp '^I, '
  assert_output --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_output --regexp '#[0-9]+'
  assert_output --regexp '    INFO -- '
  assert_output --regexp ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_output --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_null
@test "git::logger::log --output /dev/null" {
  local _message

  run --separate-stderr \
    git::logger::log \
    --output /dev/null \
    "${LOG_MESSAGES[@]}"

  assert_success
  refute_stderr
  refute_output
}

# bats test_tags=git::logger,git::logger::log,output_file
@test "git::logger::log --output tempfile" {
  local \
    _message \
    _file \
    _file_content

  _file="$(mktemp "${BATS_TEST_TMPDIR}/out.XXXXXX")"

  run --separate-stderr \
    git::logger::log \
    --output "${_file}" \
    "${LOG_MESSAGES[@]}"

  assert_success
  refute_stderr
  refute_output

  _file_content="$(cat "${_file}")"

  assert_regex "${_file_content}" '^I, '
  assert_regex "${_file_content}" "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_regex "${_file_content}" '#[0-9]+'
  assert_regex "${_file_content}" '    INFO -- '
  assert_regex "${_file_content}" ' bats_redirect_stderr_into_file: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_regex "${_file_content}" "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --caller-level 1" {
  local _message

  run --separate-stderr \
    git::logger::log \
    --caller-level 1 \
    "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   INFO -- '
  assert_stderr --regexp ' run: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --caller-level 4" {
  local _message

  run --separate-stderr \
    git::logger::log \
    --caller-level 4 \
    "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '   INFO -- '
  assert_stderr --regexp ' main: '

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --help" {
  local _message

  run --separate-stderr \
    git::logger::log \
    --help \
    "${LOG_MESSAGES[@]}"

  assert_failure "${GIT_FRIENDS_LOG_INVALID_STATUS}"
  refute_output
  assert_stderr --regexp '^Usage: git::logger::log'
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log --invalid" {
  local _message

  run --separate-stderr \
    git::logger::log \
    --invalid \
    "${LOG_MESSAGES[@]}"

  assert_failure "${GIT_FRIENDS_LOG_INVALID_STATUS}"
  refute_output
  assert_stderr --regexp "^ERROR: git::logger::log invalid option: '--invalid'"
  assert_stderr --regexp 'Usage: git::logger::log'
}

# bats test_tags=git::logger,git::logger::log,output_stderr
@test "git::logger::log -- --not-included-flag" {
  local _message

  run --separate-stderr \
    git::logger::log \
      -- \
      --not-included-flag \
      "${LOG_MESSAGES[@]}"

  assert_success
  refute_output
  assert_stderr --regexp '^I, '
  assert_stderr --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
  assert_stderr --regexp '#[0-9]+'
  assert_stderr --regexp '    INFO -- '
  assert_stderr --regexp ' bats_redirect_stderr_into_file: '

  assert_stderr --regexp '--not-included-flag'

  for _message in "${LOG_MESSAGES[@]}"; do
    assert_stderr --regexp "${_message}"
  done
}

################################################################################
# section: git::logger::datetime
################################################################################

# bats test_tags=git::logger,git::logger::datetime,output_stdout
@test "git::logger::datetime" {
  run git::logger::datetime

  assert_success
  assert_output --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
}

# bats test_tags=git::logger,git::logger::datetime,output_stdout
@test "git::logger::datetime fallback to /bin/date" {
  local original_path="${PATH}"

  PATH='/nonexistent/bin'

  run git::logger::datetime

  PATH="${original_path}"

  assert_success
  assert_output --regexp "${ISO_8601_TIMESTAMP_PATTERN}"
}

################################################################################
# section: git::logger::severity
################################################################################

# bats test_tags=git::logger,git::logger::severity,output_stdout
@test "git::logger::severity" {
  run git::logger::severity

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_INFO}"
}

# bats test_tags=git::logger,git::logger::severity,output_var
@test "git::logger::severity result" {
  local \
    result \
    _status=0

  git::logger::severity result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_INFO}"
}

# bats test_tags=git::logger,git::logger::severity,output_var
@test "git::logger::severity result -> no output" {
  local result

  run git::logger::severity result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::severity,output_stdout
@test "git::logger::severity level_override" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='debug'

  run git::logger::severity

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=git::logger,git::logger::severity,output_var
@test "git::logger::severity result level_override" {
  local \
    result \
    _status=0 \
    original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='debug'

  git::logger::severity result \
    || _status="$?"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=git::logger,git::logger::severity,output_stdout
@test "git::logger::severity level_variable_override" {
  __override__GIT_FRIENDS_LOG_LEVEL='trace'
  git::logger::level::set_variable '__override__GIT_FRIENDS_LOG_LEVEL'

  run git::logger::severity

  git::logger::level::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_TRACE}"
}

# bats test_tags=git::logger,git::logger::severity,output_var
@test "git::logger::severity result level_variable_override" {
  local \
    result \
    _status=0

  __override__GIT_FRIENDS_LOG_LEVEL='trace'
  git::logger::level::set_variable '__override__GIT_FRIENDS_LOG_LEVEL'

  git::logger::severity result \
    || _status="$?"

  git::logger::level::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_TRACE}"
}

# bats test_tags=git::logger,git::logger::severity,output_stdout
@test "git::logger::severity default_override" {
  local \
    original_log_level="${GIT_FRIENDS_LOG_LEVEL}" \
    original_log_level_default="${GIT_FRIENDS_LOG_LEVEL_DEFAULT}"

  unset GIT_FRIENDS_LOG_LEVEL
  GIT_FRIENDS_LOG_LEVEL_DEFAULT='error'

  run git::logger::severity

  GIT_FRIENDS_LOG_LEVEL_DEFAULT="${original_log_level_default}"
  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_ERROR}"
}

# bats test_tags=git::logger,git::logger::severity,output_var
@test "git::logger::severity result default_override" {
  local \
    result \
    _status=0 \
    original_log_level="${GIT_FRIENDS_LOG_LEVEL}" \
    original_log_level_default="${GIT_FRIENDS_LOG_LEVEL_DEFAULT}"

  unset GIT_FRIENDS_LOG_LEVEL
  GIT_FRIENDS_LOG_LEVEL_DEFAULT='error'

  git::logger::severity result \
    || _status="$?"

  GIT_FRIENDS_LOG_LEVEL_DEFAULT="${original_log_level_default}"
  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_ERROR}"
}

# bats test_tags=git::logger,git::logger::severity,output_stdout
@test "git::logger::severity default_variable_override" {
  unset __override__GIT_FRIENDS_LOG_LEVEL
  __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT='warning'
  git::logger::level::set_variable '__override__GIT_FRIENDS_LOG_LEVEL'
  git::logger::level_default::set_variable '__override__GIT_FRIENDS_LOG_LEVEL_DEFAULT'

  run git::logger::severity

  git::logger::level_default::unset_variable
  git::logger::level::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_WARNING}"
}

# bats test_tags=git::logger,git::logger::severity,output_var
@test "git::logger::severity result default_variable_override" {
  local result _status=0

  unset __override__GIT_FRIENDS_LOG_LEVEL
  __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT='warning'
  git::logger::level::set_variable '__override__GIT_FRIENDS_LOG_LEVEL'
  git::logger::level_default::set_variable '__override__GIT_FRIENDS_LOG_LEVEL_DEFAULT'

  git::logger::severity result \
    || _status="$?"

  git::logger::level_default::unset_variable
  git::logger::level::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_WARNING}"
}

################################################################################
# section: git::logger::severity_from_level
################################################################################

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level trace" {
  run git::logger::severity_from_level trace

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_TRACE}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level TRACE" {
  run git::logger::severity_from_level TRACE

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_TRACE}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level Trace" {
  run git::logger::severity_from_level Trace

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_TRACE}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level trace result" {
  local \
    result \
    _status=0

  git::logger::severity_from_level trace result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_TRACE}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level trace result -> no output" {
  local result

  run git::logger::severity_from_level trace result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level debug" {
  run git::logger::severity_from_level debug

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level DEBUG" {
  run git::logger::severity_from_level DEBUG

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level Debug" {
  run git::logger::severity_from_level Debug

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level debug result" {
  local \
    result \
    _status=0

  git::logger::severity_from_level debug result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_DEBUG}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level debug result -> no output" {
  local result

  run git::logger::severity_from_level debug result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level info" {
  run git::logger::severity_from_level info

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_INFO}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level INFO" {
  run git::logger::severity_from_level INFO

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_INFO}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level Info" {
  run git::logger::severity_from_level Info

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_INFO}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level info result" {
  local \
    result \
    _status=0

  git::logger::severity_from_level info result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_INFO}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level info result -> no output" {
  local result

  run git::logger::severity_from_level info result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level warning" {
  run git::logger::severity_from_level warning

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_WARNING}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level WARNING" {
  run git::logger::severity_from_level WARNING

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_WARNING}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level Warning" {
  run git::logger::severity_from_level Warning

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_WARNING}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level warning result" {
  local \
    result \
    _status=0

  git::logger::severity_from_level warning result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_WARNING}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level warning result -> no output" {
  local result

  run git::logger::severity_from_level warning result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level error" {
  run git::logger::severity_from_level error

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_ERROR}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level ERROR" {
  run git::logger::severity_from_level ERROR

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_ERROR}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level Error" {
  run git::logger::severity_from_level Error

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_ERROR}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level error result" {
  local \
    result \
    _status=0

  git::logger::severity_from_level error result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_ERROR}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level error result -> no output" {
  local result

  run git::logger::severity_from_level error result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level fatal" {
  run git::logger::severity_from_level fatal

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_FATAL}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level FATAL" {
  run git::logger::severity_from_level FATAL

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_FATAL}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level Fatal" {
  run git::logger::severity_from_level Fatal

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_FATAL}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level fatal result" {
  local \
    result \
    _status=0

  git::logger::severity_from_level fatal result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_FATAL}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level fatal result -> no output" {
  local result

  run git::logger::severity_from_level fatal result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level invalid" {
  run git::logger::severity_from_level invalid

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_FATAL}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level INVALID" {
  run git::logger::severity_from_level INVALID

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_FATAL}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_stdout
@test "git::logger::severity_from_level Invalid" {
  run git::logger::severity_from_level Invalid

  assert_success
  assert_output "${GIT_FRIENDS_LOG_SEVERITY_FATAL}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level invalid result" {
  local \
    result \
    _status=0

  git::logger::severity_from_level invalid result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" "${GIT_FRIENDS_LOG_SEVERITY_FATAL}"
}

# bats test_tags=git::logger,git::logger::severity_from_level,output_var
@test "git::logger::severity_from_level invalid result -> no output" {
  local result

  run git::logger::severity_from_level invalid result

  assert_success
  refute_output
}

################################################################################
# section: git::logger::level
################################################################################

# bats test_tags=git::logger,git::logger::level,output_stdout
@test "git::logger::level" {
  run git::logger::level

  assert_success
  assert_output 'info'
}

# bats test_tags=git::logger,git::logger::level,output_var
@test "git::logger::level result" {
  local \
    result \
    _status=0

  git::logger::level result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'info'
}

# bats test_tags=git::logger,git::logger::level,output_var
@test "git::logger::level result -> no output" {
  local result

  run git::logger::level result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::level,output_stdout
@test "git::logger::level level_override" {
  local original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='debug'

  run git::logger::level

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  assert_output 'debug'
}

# bats test_tags=git::logger,git::logger::level,output_var
@test "git::logger::level result level_override" {
  local \
    result \
    _status=0 \
    original_log_level="${GIT_FRIENDS_LOG_LEVEL}"

  GIT_FRIENDS_LOG_LEVEL='debug'

  git::logger::level result \
    || _status="$?"

  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'debug'
}

# bats test_tags=git::logger,git::logger::level,output_stdout
@test "git::logger::level level_variable_override" {
  __override__GIT_FRIENDS_LOG_LEVEL='trace'
  git::logger::level::set_variable '__override__GIT_FRIENDS_LOG_LEVEL'

  run git::logger::level

  git::logger::level::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL

  assert_success
  assert_output 'trace'
}

# bats test_tags=git::logger,git::logger::level,output_var
@test "git::logger::level result level_variable_override" {
  local \
    result \
    _status=0

  __override__GIT_FRIENDS_LOG_LEVEL='trace'
  git::logger::level::set_variable '__override__GIT_FRIENDS_LOG_LEVEL'

  git::logger::level result \
    || _status="$?"

  git::logger::level::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL

  assert_equal "${_status}" 0
  assert_equal "${result}" 'trace'
}

# bats test_tags=git::logger,git::logger::level,output_stdout
@test "git::logger::level default_override" {
  local \
    original_log_level="${GIT_FRIENDS_LOG_LEVEL}" \
    original_log_level_default="${GIT_FRIENDS_LOG_LEVEL_DEFAULT}"

  unset GIT_FRIENDS_LOG_LEVEL
  GIT_FRIENDS_LOG_LEVEL_DEFAULT='error'

  run git::logger::level

  GIT_FRIENDS_LOG_LEVEL_DEFAULT="${original_log_level_default}"
  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_success
  assert_output 'error'
}

# bats test_tags=git::logger,git::logger::level,output_var
@test "git::logger::level result default_override" {
  local \
    result \
    _status=0 \
    original_log_level="${GIT_FRIENDS_LOG_LEVEL}" \
    original_log_level_default="${GIT_FRIENDS_LOG_LEVEL_DEFAULT}"

  unset GIT_FRIENDS_LOG_LEVEL
  GIT_FRIENDS_LOG_LEVEL_DEFAULT='error'

  git::logger::level result \
    || _status="$?"

  GIT_FRIENDS_LOG_LEVEL_DEFAULT="${original_log_level_default}"
  GIT_FRIENDS_LOG_LEVEL="${original_log_level}"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'error'
}

# bats test_tags=git::logger,git::logger::level,output_stdout
@test "git::logger::level default_variable_override" {
  unset __override__GIT_FRIENDS_LOG_LEVEL
  __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT='warning'
  git::logger::level::set_variable '__override__GIT_FRIENDS_LOG_LEVEL'
  git::logger::level_default::set_variable '__override__GIT_FRIENDS_LOG_LEVEL_DEFAULT'

  run git::logger::level

  git::logger::level_default::unset_variable
  git::logger::level::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT

  assert_success
  assert_output 'warning'
}

# bats test_tags=git::logger,git::logger::level,output_var
@test "git::logger::level result default_variable_override" {
  local result _status=0

  unset __override__GIT_FRIENDS_LOG_LEVEL
  __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT='warning'
  git::logger::level::set_variable '__override__GIT_FRIENDS_LOG_LEVEL'
  git::logger::level_default::set_variable '__override__GIT_FRIENDS_LOG_LEVEL_DEFAULT'

  git::logger::level result \
    || _status="$?"

  git::logger::level_default::unset_variable
  git::logger::level::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" 'warning'
}

################################################################################
# section: git::logger::level::variable
################################################################################

# bats test_tags=git::logger,git::logger::level::variable,output_stdout
@test "git::logger::level::variable" {
  run git::logger::level::variable

  assert_success
  assert_output 'GIT_FRIENDS_LOG_LEVEL'
}

# bats test_tags=git::logger,git::logger::level::variable,output_var
@test "git::logger::level::variable result" {
  local \
    result \
    _status=0

  git::logger::level::variable result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'GIT_FRIENDS_LOG_LEVEL'
}

# bats test_tags=git::logger,git::logger::level::variable,output_var
@test "git::logger::level::variable result -> no output" {
  local result

  run git::logger::level::variable result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::level::variable,output_stdout
@test "git::logger::level::variable variable_override" {
  __override__GIT_FRIENDS_LOG_LEVEL='debug'
  git::logger::level::set_variable '__override__GIT_FRIENDS_LOG_LEVEL'

  run git::logger::level::variable

  git::logger::level::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL

  assert_success
  assert_output '__override__GIT_FRIENDS_LOG_LEVEL'
}

# bats test_tags=git::logger,git::logger::level::variable,output_var
@test "git::logger::level::variable result variable_override" {
  local \
    result \
    _status=0

  __override__GIT_FRIENDS_LOG_LEVEL='debug'
  git::logger::level::set_variable '__override__GIT_FRIENDS_LOG_LEVEL'

  git::logger::level::variable result \
    || _status="$?"

  git::logger::level::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL

  assert_equal "${_status}" 0
  assert_equal "${result}" '__override__GIT_FRIENDS_LOG_LEVEL'
}

################################################################################
# section: git::logger::level_default
################################################################################

# bats test_tags=git::logger,git::logger::level_default,output_stdout
@test "git::logger::level_default" {
  run git::logger::level_default

  assert_success
  assert_output 'info'
}

# bats test_tags=git::logger,git::logger::level_default,output_var
@test "git::logger::level_default result" {
  local \
    result \
    _status=0

  git::logger::level_default result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'info'
}

# bats test_tags=git::logger,git::logger::level_default,output_var
@test "git::logger::level_default result -> no output" {
  local result

  run git::logger::level_default result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::level_default,output_stdout
@test "git::logger::level_default override" {
  local original_log_level_default="${GIT_FRIENDS_LOG_LEVEL_DEFAULT}"

  GIT_FRIENDS_LOG_LEVEL_DEFAULT='error'

  run git::logger::level_default

  GIT_FRIENDS_LOG_LEVEL_DEFAULT="${original_log_level_default}"

  assert_success
  assert_output 'error'
}

# bats test_tags=git::logger,git::logger::level_default,output_var
@test "git::logger::level_default result override" {
  local \
    result \
    _status=0 \
    original_log_level_default="${GIT_FRIENDS_LOG_LEVEL_DEFAULT}"

  GIT_FRIENDS_LOG_LEVEL_DEFAULT='error'

  git::logger::level_default result \
    || _status="$?"

  GIT_FRIENDS_LOG_LEVEL_DEFAULT="${original_log_level_default}"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'error'
}

# bats test_tags=git::logger,git::logger::level_default,output_stdout
@test "git::logger::level_default variable_override" {
  __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT='warning'
  git::logger::level_default::set_variable '__override__GIT_FRIENDS_LOG_LEVEL_DEFAULT'

  run git::logger::level_default

  git::logger::level_default::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT

  assert_success
  assert_output 'warning'
}

# bats test_tags=git::logger,git::logger::level_default,output_var
@test "git::logger::level_default result variable_override" {
  local \
    result \
    _status=0

  __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT='warning'
  git::logger::level_default::set_variable '__override__GIT_FRIENDS_LOG_LEVEL_DEFAULT'

  git::logger::level_default result \
    || _status="$?"

  git::logger::level_default::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" 'warning'
}

################################################################################
# section: git::logger::level_default::variable
################################################################################

# bats test_tags=git::logger,git::logger::level_default::variable,output_stdout
@test "git::logger::level_default::variable" {
  run git::logger::level_default::variable

  assert_success
  assert_output 'GIT_FRIENDS_LOG_LEVEL_DEFAULT'
}

# bats test_tags=git::logger,git::logger::level_default::variable,output_var
@test "git::logger::level_default::variable result" {
  local \
    result \
    _status=0

  git::logger::level_default::variable result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'GIT_FRIENDS_LOG_LEVEL_DEFAULT'
}

# bats test_tags=git::logger,git::logger::level_default::variable,output_var
@test "git::logger::level_default::variable result -> no output" {
  local result

  run git::logger::level_default::variable result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::level_default::variable,output_stdout
@test "git::logger::level_default::variable variable_override" {
  __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT='debug'
  git::logger::level_default::set_variable '__override__GIT_FRIENDS_LOG_LEVEL_DEFAULT'

  run git::logger::level_default::variable

  git::logger::level_default::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT

  assert_success
  assert_output '__override__GIT_FRIENDS_LOG_LEVEL_DEFAULT'
}

# bats test_tags=git::logger,git::logger::level_default::variable,output_var
@test "git::logger::level_default::variable result variable_override" {
  local \
    result \
    _status=0

  __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT='debug'
  git::logger::level_default::set_variable '__override__GIT_FRIENDS_LOG_LEVEL_DEFAULT'

  git::logger::level_default::variable result \
    || _status="$?"

  git::logger::level_default::unset_variable
  unset __override__GIT_FRIENDS_LOG_LEVEL_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" '__override__GIT_FRIENDS_LOG_LEVEL_DEFAULT'
}

################################################################################
# section: git::logger::output_default
################################################################################

# bats test_tags=git::logger,git::logger::output_default,output_stdout
@test "git::logger::output_default" {
  run git::logger::output_default

  assert_success
  assert_output '/dev/stderr'
}

# bats test_tags=git::logger,git::logger::output_default,output_var
@test "git::logger::output_default result" {
  local \
    result \
    _status=0

  git::logger::output_default result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" '/dev/stderr'
}

# bats test_tags=git::logger,git::logger::output_default,output_var
@test "git::logger::output_default result -> no output" {
  local result

  run git::logger::output_default result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::output_default,output_stdout
@test "git::logger::output_default override" {
  local original_log_output_default="${GIT_FRIENDS_LOG_OUTPUT_DEFAULT}"

  GIT_FRIENDS_LOG_OUTPUT_DEFAULT='/dev/stdout'

  run git::logger::output_default

  GIT_FRIENDS_LOG_OUTPUT_DEFAULT="${original_log_output_default}"

  assert_success
  assert_output '/dev/stdout'
}

# bats test_tags=git::logger,git::logger::output_default,output_var
@test "git::logger::output_default result override" {
  local \
    result \
    _status=0 \
    original_log_output_default="${GIT_FRIENDS_LOG_OUTPUT_DEFAULT}"

  GIT_FRIENDS_LOG_OUTPUT_DEFAULT='/dev/stdout'

  git::logger::output_default result \
    || _status="$?"

  GIT_FRIENDS_LOG_OUTPUT_DEFAULT="${original_log_output_default}"

  assert_equal "${_status}" 0
  assert_equal "${result}" '/dev/stdout'
}

# bats test_tags=git::logger,git::logger::output_default,output_stdout
@test "git::logger::output_default variable_override" {
  __override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT='my.log'
  git::logger::output_default::set_variable '__override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT'

  run git::logger::output_default

  git::logger::output_default::unset_variable
  unset __override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT

  assert_success
  assert_output 'my.log'
}

# bats test_tags=git::logger,git::logger::output_default,output_var
@test "git::logger::output_default result variable_override" {
  local \
    result \
    _status=0

  __override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT='my.log'
  git::logger::output_default::set_variable '__override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT'

  git::logger::output_default result \
    || _status="$?"

  git::logger::output_default::unset_variable
  unset __override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" 'my.log'
}

################################################################################
# section: git::logger::output_default::variable
################################################################################

# bats test_tags=git::logger,git::logger::output_default::variable,output_stdout
@test "git::logger::output_default::variable" {
  run git::logger::output_default::variable

  assert_success
  assert_output 'GIT_FRIENDS_LOG_OUTPUT_DEFAULT'
}

# bats test_tags=git::logger,git::logger::output_default::variable,output_var
@test "git::logger::output_default::variable result" {
  local \
    result \
    _status=0

  git::logger::output_default::variable result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'GIT_FRIENDS_LOG_OUTPUT_DEFAULT'
}

# bats test_tags=git::logger,git::logger::output_default::variable,output_var
@test "git::logger::output_default::variable result -> no output" {
  local result

  run git::logger::output_default::variable result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::output_default::variable,output_stdout
@test "git::logger::output_default::variable variable_override" {
  __override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT='debug'
  git::logger::output_default::set_variable '__override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT'

  run git::logger::output_default::variable

  git::logger::output_default::unset_variable
  unset __override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT

  assert_success
  assert_output '__override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT'
}

# bats test_tags=git::logger,git::logger::output_default::variable,output_var
@test "git::logger::output_default::variable result variable_override" {
  local \
    result \
    _status=0

  __override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT='debug'
  git::logger::output_default::set_variable '__override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT'

  git::logger::output_default::variable result \
    || _status="$?"

  git::logger::output_default::unset_variable
  unset __override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT

  assert_equal "${_status}" 0
  assert_equal "${result}" '__override__GIT_FRIENDS_LOG_OUTPUT_DEFAULT'
}

################################################################################
# section: git::logger::is_silenced
################################################################################

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced" {
  run git::logger::is_silenced

  assert_failure
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced override = 1" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run git::logger::is_silenced

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced variable_override > 1" {
  __override__GIT_FRIENDS_LOG_SILENCE=42
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  run git::logger::is_silenced

  git::logger::silence::unset_variable
  unset __override__GIT_FRIENDS_LOG_SILENCE

  assert_success
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced override = true" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=true

  run git::logger::is_silenced

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced variable_override = TRUE" {
  __override__GIT_FRIENDS_LOG_SILENCE=TRUE
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  run git::logger::is_silenced

  git::logger::silence::unset_variable
  unset __override__GIT_FRIENDS_LOG_SILENCE

  assert_success
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced override = yes" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=yes

  run git::logger::is_silenced

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced variable_override = YES" {
  __override__GIT_FRIENDS_LOG_SILENCE=YES
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  run git::logger::is_silenced

  git::logger::silence::unset_variable
  unset __override__GIT_FRIENDS_LOG_SILENCE

  assert_success
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced override = 0" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=0

  run git::logger::is_silenced

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_failure
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced variable_override < 0" {
  __override__GIT_FRIENDS_LOG_SILENCE=-42
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  run git::logger::is_silenced

  git::logger::silence::unset_variable
  unset __override__GIT_FRIENDS_LOG_SILENCE

  assert_failure
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced override = false" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=false

  run git::logger::is_silenced

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_failure
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced variable_override = FALSE" {
  __override__GIT_FRIENDS_LOG_SILENCE=FALSE
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  run git::logger::is_silenced

  git::logger::silence::unset_variable
  unset __override__GIT_FRIENDS_LOG_SILENCE

  assert_failure
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced override = no" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=no

  run git::logger::is_silenced

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_failure
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced variable_override = NO" {
  __override__GIT_FRIENDS_LOG_SILENCE=NO
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  run git::logger::is_silenced

  git::logger::silence::unset_variable
  unset __override__GIT_FRIENDS_LOG_SILENCE

  assert_failure
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced override = invalid" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=invalid

  run git::logger::is_silenced

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_failure
}

# bats test_tags=git::logger,git::logger::is_silenced
@test "git::logger::is_silenced variable_override unset" {
  unset __override__GIT_FRIENDS_LOG_SILENCE
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  run git::logger::is_silenced

  git::logger::silence::unset_variable

  assert_failure
}

################################################################################
# section: git::logger::silence
################################################################################

# bats test_tags=git::logger,git::logger::silence,output_stdout
@test "git::logger::silence" {
  run git::logger::silence

  assert_success
  assert_output 0
}

# bats test_tags=git::logger,git::logger::silence,output_var
@test "git::logger::silence result" {
  local \
    result \
    _status=0

  git::logger::silence result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 0
}

# bats test_tags=git::logger,git::logger::silence,output_var
@test "git::logger::silence result -> no output" {
  local result

  run git::logger::silence result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::silence,output_stdout
@test "git::logger::silence override" {
  local original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  run git::logger::silence

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_success
  assert_output 1
}

# bats test_tags=git::logger,git::logger::silence,output_var
@test "git::logger::silence result override" {
  local \
    result \
    _status=0 \
    original_log_silence="${GIT_FRIENDS_LOG_SILENCE}"

  GIT_FRIENDS_LOG_SILENCE=1

  git::logger::silence result \
    || _status="$?"

  GIT_FRIENDS_LOG_SILENCE="${original_log_silence}"

  assert_equal "${_status}" 0
  assert_equal "${result}" 1
}

# bats test_tags=git::logger,git::logger::silence,output_stdout
@test "git::logger::silence variable_override" {
  __override__GIT_FRIENDS_LOG_SILENCE=42
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  run git::logger::silence

  git::logger::silence::unset_variable
  unset __override__GIT_FRIENDS_LOG_SILENCE

  assert_success
  assert_output 42
}

# bats test_tags=git::logger,git::logger::silence,output_var
@test "git::logger::silence result variable_override" {
  local \
    result \
    _status=0

  __override__GIT_FRIENDS_LOG_SILENCE=42
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  git::logger::silence result \
    || _status="$?"

  git::logger::silence::unset_variable
  unset __override__GIT_FRIENDS_LOG_SILENCE

  assert_equal "${_status}" 0
  assert_equal "${result}" 42
}

################################################################################
# section: git::logger::silence::variable
################################################################################

# bats test_tags=git::logger,git::logger::silence::variable,output_stdout
@test "git::logger::silence::variable" {
  run git::logger::silence::variable

  assert_success
  assert_output 'GIT_FRIENDS_LOG_SILENCE'
}

# bats test_tags=git::logger,git::logger::silence::variable,output_var
@test "git::logger::silence::variable result" {
  local \
    result \
    _status=0

  git::logger::silence::variable result \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${result}" 'GIT_FRIENDS_LOG_SILENCE'
}

# bats test_tags=git::logger,git::logger::silence::variable,output_var
@test "git::logger::silence::variable result -> no output" {
  local result

  run git::logger::silence::variable result

  assert_success
  refute_output
}

# bats test_tags=git::logger,git::logger::silence::variable,output_stdout
@test "git::logger::silence::variable variable_override" {
  __override__GIT_FRIENDS_LOG_SILENCE=1
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  run git::logger::silence::variable

  git::logger::silence::unset_variable
  unset __override__GIT_FRIENDS_LOG_SILENCE

  assert_success
  assert_output '__override__GIT_FRIENDS_LOG_SILENCE'
}

# bats test_tags=git::logger,git::logger::silence::variable,output_var
@test "git::logger::silence::variable result variable_override" {
  local \
    result \
    _status=0

  __override__GIT_FRIENDS_LOG_SILENCE=1
  git::logger::silence::set_variable '__override__GIT_FRIENDS_LOG_SILENCE'

  git::logger::silence::variable result \
    || _status="$?"

  git::logger::silence::unset_variable
  unset __override__GIT_FRIENDS_LOG_SILENCE

  assert_equal "${_status}" 0
  assert_equal "${result}" '__override__GIT_FRIENDS_LOG_SILENCE'
}
