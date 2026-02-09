#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/cscope.sh'

################################################################################
# git::cscope::generate
################################################################################

# bats test_tags=function::git::cscope::generate
@test "git::cscope::generate fails when cscope command not found" {
  local original_path="${PATH}"

  PATH='/nonexistent/bin'

  run git::cscope::generate

  PATH="${original_path}"

  assert_failure
}

# bats test_tags=function::git::cscope::generate
@test "git::cscope::generate fails outside a git repository" {
  local mock_dir="${BATS_TEST_TMPDIR}/bin"
  local work_dir="${BATS_TEST_TMPDIR}/not-a-repo"

  mkdir -p "${mock_dir}" "${work_dir}"
  cat > "${mock_dir}/cscope" <<'MOCK'
#!/bin/bash
exit 0
MOCK
  chmod +x "${mock_dir}/cscope"

  local original_path="${PATH}"
  PATH="${mock_dir}:${PATH}"

  cd "${work_dir}"

  run git::cscope::generate

  PATH="${original_path}"

  assert_failure
}

# bats test_tags=function::git::cscope::generate
@test "git::cscope::generate succeeds with mock cscope" {
  local mock_dir="${BATS_TEST_TMPDIR}/bin"
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  mkdir -p "${mock_dir}"
  git init "${repo_dir}"

  # Create a tracked file so git ls-files has output
  touch "${repo_dir}/example.c"
  git -C "${repo_dir}" add 'example.c'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  # Mock cscope: parse the -f flag to find output file and create it
  # Also create the .in and .po companion files cscope normally generates
  cat > "${mock_dir}/cscope" <<'MOCK'
#!/bin/bash
cat > /dev/null  # consume stdin
outfile=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) outfile="$2"; shift 2 ;;
    *)  shift ;;
  esac
done
if [[ -n "${outfile}" ]]; then
  touch "${outfile}"
  touch "${outfile}.in"
  touch "${outfile}.po"
fi
exit 0
MOCK
  chmod +x "${mock_dir}/cscope"

  local original_path="${PATH}"
  PATH="${mock_dir}:${PATH}"

  cd "${repo_dir}"

  run git::cscope::generate

  PATH="${original_path}"

  assert_success
}

# bats test_tags=function::git::cscope::generate
@test "git::cscope::generate fails when cscope command errors" {
  local mock_dir="${BATS_TEST_TMPDIR}/bin"
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  mkdir -p "${mock_dir}"
  git init "${repo_dir}"

  touch "${repo_dir}/example.c"
  git -C "${repo_dir}" add 'example.c'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  # Mock cscope that always fails
  cat > "${mock_dir}/cscope" <<'MOCK'
#!/bin/bash
cat > /dev/null  # consume stdin
exit 1
MOCK
  chmod +x "${mock_dir}/cscope"

  local original_path="${PATH}"
  PATH="${mock_dir}:${PATH}"

  cd "${repo_dir}"

  run git::cscope::generate

  PATH="${original_path}"

  assert_failure
}

# bats test_tags=function::git::cscope::generate
@test "git::cscope::generate passes extra flags to cscope" {
  local mock_dir="${BATS_TEST_TMPDIR}/bin"
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  mkdir -p "${mock_dir}"
  git init "${repo_dir}"

  touch "${repo_dir}/example.c"
  git -C "${repo_dir}" add 'example.c'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  # Mock cscope: verify custom flag is present
  cat > "${mock_dir}/cscope" <<'MOCK'
#!/bin/bash
cat > /dev/null  # consume stdin
found_custom=0
outfile=""
for arg in "$@"; do
  if [[ "${arg}" == '-k' ]]; then
    found_custom=1
  fi
done
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) outfile="$2"; shift 2 ;;
    *)  shift ;;
  esac
done
if [[ -n "${outfile}" ]]; then
  touch "${outfile}"
  touch "${outfile}.in"
  touch "${outfile}.po"
fi
if [[ "${found_custom}" -ne 1 ]]; then
  echo "ERROR: custom flag not passed" >&2
  exit 1
fi
exit 0
MOCK
  chmod +x "${mock_dir}/cscope"

  local original_path="${PATH}"
  PATH="${mock_dir}:${PATH}"

  cd "${repo_dir}"

  run git::cscope::generate '-k'

  PATH="${original_path}"

  assert_success
}

################################################################################
# git::cscope::files
################################################################################

# bats test_tags=function::git::cscope::files
@test "git::cscope::files lists tracked files matching language patterns" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"

  # Create files matching cscope language patterns
  touch "${repo_dir}/main.c"
  touch "${repo_dir}/header.h"
  touch "${repo_dir}/app.py"
  touch "${repo_dir}/Main.java"
  touch "${repo_dir}/impl.cpp"
  touch "${repo_dir}/sketch.ino"

  git -C "${repo_dir}" add .
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  cd "${repo_dir}"

  run git::cscope::files

  assert_success
  assert_line 'main.c'
  assert_line 'header.h'
  assert_line 'app.py'
  assert_line 'Main.java'
  assert_line 'impl.cpp'
  assert_line 'sketch.ino'
}

# bats test_tags=function::git::cscope::files
@test "git::cscope::files excludes non-matching file types" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"

  # Create files that do NOT match cscope language patterns
  touch "${repo_dir}/readme.md"
  touch "${repo_dir}/style.css"
  touch "${repo_dir}/app.js"
  touch "${repo_dir}/data.json"
  touch "${repo_dir}/Makefile"

  git -C "${repo_dir}" add .
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  cd "${repo_dir}"

  run git::cscope::files

  assert_success
  refute_output
}

# bats test_tags=function::git::cscope::files
@test "git::cscope::files lists C++ header variants" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"

  # Create C++ header variants
  touch "${repo_dir}/a.hh"
  touch "${repo_dir}/b.hpp"
  touch "${repo_dir}/c.hxx"
  touch "${repo_dir}/d.h++"
  touch "${repo_dir}/e.hp"
  touch "${repo_dir}/f.H"

  git -C "${repo_dir}" add .
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  cd "${repo_dir}"

  run git::cscope::files

  assert_success
  assert_line 'a.hh'
  assert_line 'b.hpp'
  assert_line 'c.hxx'
  assert_line 'd.h++'
  assert_line 'e.hp'
  assert_line 'f.H'
}

# bats test_tags=function::git::cscope::files
@test "git::cscope::files lists C++ source variants" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"

  # Create C++ source variants
  touch "${repo_dir}/a.cc"
  touch "${repo_dir}/b.cpp"
  touch "${repo_dir}/c.cxx"
  touch "${repo_dir}/d.c++"
  touch "${repo_dir}/e.cp"
  touch "${repo_dir}/f.C"

  git -C "${repo_dir}" add .
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  cd "${repo_dir}"

  run git::cscope::files

  assert_success
  assert_line 'a.cc'
  assert_line 'b.cpp'
  assert_line 'c.cxx'
  assert_line 'd.c++'
  assert_line 'e.cp'
  assert_line 'f.C'
}

# bats test_tags=function::git::cscope::files
@test "git::cscope::files lists properties files" {
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  git init "${repo_dir}"

  touch "${repo_dir}/config.properties"

  git -C "${repo_dir}" add .
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  cd "${repo_dir}"

  run git::cscope::files

  assert_success
  assert_line 'config.properties'
}
