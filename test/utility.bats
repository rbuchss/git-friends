#!/usr/bin/env bats

load test_helper

source "$(repo_root)/git-friends/src/utility.sh"

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
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'y' \
    || _status="$?"

  assert_equal 0 "${_status}"
  assert_null_or_empty "${all_response}"
}

@test "git::utility::ask 'build snowman?' all_response <<< 'yes'" {
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'yes' \
    || _status="$?"

  assert_equal 0 "${_status}"
  assert_null_or_empty "${all_response}"
}

@test "git::utility::ask 'build snowman?' all_response <<< 'n'" {
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'n' \
    || _status="$?"

  assert_equal 1 "${_status}"
  assert_null_or_empty "${all_response}"
}

@test "git::utility::ask 'build snowman?' all_response <<< 'no'" {
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'no' \
    || _status="$?"

  assert_equal 1 "${_status}"
  assert_null_or_empty "${all_response}"
}

@test "git::utility::ask 'build snowman?' all_response <<< 'yarp'" {
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'yarp' \
    || _status="$?"

  assert_equal 1 "${_status}"
  assert_null_or_empty "${all_response}"
}

@test "git::utility::ask 'build snowman?' all_response <<< 'a'" {
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'a' \
    || _status="$?"

  assert_equal 0 "${_status}"
  assert_equal 0 "${all_response}"

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal 0 "${_status}"
  assert_equal 0 "${all_response}"
}

@test "git::utility::ask 'build snowman?' all_response <<< 'all'" {
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'all'\
    || _status="$?"

  assert_equal 0 "${_status}"
  assert_equal 0 "${all_response}"

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal 0 "${_status}"
  assert_equal 0 "${all_response}"
}

@test "git::utility::ask 'build snowman?' all_response <<< 'z'" {
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'z' \
    || _status="$?"

  assert_equal 1 "${_status}"
  assert_equal 1 "${all_response}"

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal 1 "${_status}"
  assert_equal 1 "${all_response}"
}

@test "git::utility::ask 'build snowman?' all_response <<< 'none'" {
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'none' \
    || _status="$?"

  assert_equal 1 "${_status}"
  assert_equal 1 "${all_response}"

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal 1 "${_status}"
  assert_equal 1 "${all_response}"
}

@test "git::utility::ask 'build snowman?' all_response=0" {
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response=0 \
    _status=0

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal 0 "${_status}"
  assert_equal 0 "${all_response}"
}

@test "git::utility::ask 'build snowman?' all_response=1" {
  # NOTE: bats `run` cannot check variable being set
  # since run is done in subshell ...
  local \
    all_response=1 \
    _status=0

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal 1 "${_status}"
  assert_equal 1 "${all_response}"
}
