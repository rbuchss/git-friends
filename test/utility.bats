#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/utility.sh'

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
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'y' \
    || _status="$?"

  assert_equal "${_status}" 0
  assert [ -z "${all_response}" ]
}

@test "git::utility::ask 'build snowman?' all_response <<< 'yes'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'yes' \
    || _status="$?"

  assert_equal "${_status}" 0
  assert [ -z "${all_response}" ]
}

@test "git::utility::ask 'build snowman?' all_response <<< 'n'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'n' \
    || _status="$?"

  assert_equal "${_status}" 1
  assert [ -z "${all_response}" ]
}

@test "git::utility::ask 'build snowman?' all_response <<< 'no'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'no' \
    || _status="$?"

  assert_equal "${_status}" 1
  assert [ -z "${all_response}" ]
}

@test "git::utility::ask 'build snowman?' all_response <<< 'yarp'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'yarp' \
    || _status="$?"

  assert_equal "${_status}" 1
  assert [ -z "${all_response}" ]
}

@test "git::utility::ask 'build snowman?' all_response <<< 'a'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'a' \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${all_response}" 0

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${all_response}" 0
}

@test "git::utility::ask 'build snowman?' all_response <<< 'all'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'all'\
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${all_response}" 0

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${all_response}" 0
}

@test "git::utility::ask 'build snowman?' all_response <<< 'z'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'z' \
    || _status="$?"

  assert_equal "${_status}" 1
  assert_equal "${all_response}" 1

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 1
  assert_equal "${all_response}" 1
}

@test "git::utility::ask 'build snowman?' all_response <<< 'none'" {
  local \
    all_response \
    _status=0

  git::utility::ask 'build snowman?' all_response <<< 'none' \
    || _status="$?"

  assert_equal "${_status}" 1
  assert_equal "${all_response}" 1

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 1
  assert_equal "${all_response}" 1
}

@test "git::utility::ask 'build snowman?' all_response=0" {
  local \
    all_response=0 \
    _status=0

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 0
  assert_equal "${all_response}" 0
}

@test "git::utility::ask 'build snowman?' all_response=1" {
  local \
    all_response=1 \
    _status=0

  git::utility::ask 'build snowman?' all_response \
    || _status="$?"

  assert_equal "${_status}" 1
  assert_equal "${all_response}" 1
}
