#!/usr/bin/env bats

load test_helper

setup_with_coverage 'git-friends/src/ctags.sh'

################################################################################
# git::ctags::generate
################################################################################

# bats test_tags=function::git::ctags::generate
@test "git::ctags::generate fails when ctags command not found" {
  local original_path="${PATH}"

  PATH='/nonexistent/bin'

  run git::ctags::generate

  PATH="${original_path}"

  assert_failure
}

# bats test_tags=function::git::ctags::generate
@test "git::ctags::generate fails outside a git repository" {
  local mock_dir="${BATS_TEST_TMPDIR}/bin"
  local work_dir="${BATS_TEST_TMPDIR}/not-a-repo"

  mkdir -p "${mock_dir}" "${work_dir}"
  cat >"${mock_dir}/ctags" <<'MOCK'
#!/bin/bash
exit 0
MOCK
  chmod +x "${mock_dir}/ctags"

  local original_path="${PATH}"
  PATH="${mock_dir}:${PATH}"

  cd "${work_dir}"

  run git::ctags::generate

  PATH="${original_path}"

  assert_failure
}

# bats test_tags=function::git::ctags::generate
@test "git::ctags::generate succeeds with mock ctags" {
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

  # Mock ctags: parse the -f flag to find output file and create it
  cat >"${mock_dir}/ctags" <<'MOCK'
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
fi
exit 0
MOCK
  chmod +x "${mock_dir}/ctags"

  local original_path="${PATH}"
  PATH="${mock_dir}:${PATH}"

  cd "${repo_dir}"

  run git::ctags::generate

  PATH="${original_path}"

  assert_success
}

# bats test_tags=function::git::ctags::generate
@test "git::ctags::generate picks up .ctagsignore when present" {
  local mock_dir="${BATS_TEST_TMPDIR}/bin"
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  mkdir -p "${mock_dir}"
  git init "${repo_dir}"

  touch "${repo_dir}/example.c"
  git -C "${repo_dir}" add 'example.c'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  # Create .ctagsignore so the code path is triggered
  echo 'node_modules' >"${repo_dir}/.ctagsignore"

  # Mock ctags: verify --exclude=@.ctagsignore is in the args
  cat >"${mock_dir}/ctags" <<'MOCK'
#!/bin/bash
cat > /dev/null  # consume stdin
found_ignore=0
outfile=""
for arg in "$@"; do
  case "${arg}" in
    --exclude=@.ctagsignore) found_ignore=1 ;;
    -f) ;;
    *)  ;;
  esac
done
# Parse -f separately
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f) outfile="$2"; shift 2 ;;
    *)  shift ;;
  esac
done
if [[ -n "${outfile}" ]]; then
  touch "${outfile}"
fi
if [[ "${found_ignore}" -ne 1 ]]; then
  echo "ERROR: --exclude=@.ctagsignore not found" >&2
  exit 1
fi
exit 0
MOCK
  chmod +x "${mock_dir}/ctags"

  local original_path="${PATH}"
  PATH="${mock_dir}:${PATH}"

  cd "${repo_dir}"

  run git::ctags::generate

  PATH="${original_path}"

  assert_success
}

# bats test_tags=function::git::ctags::generate
@test "git::ctags::generate fails when ctags command errors" {
  local mock_dir="${BATS_TEST_TMPDIR}/bin"
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  mkdir -p "${mock_dir}"
  git init "${repo_dir}"

  touch "${repo_dir}/example.c"
  git -C "${repo_dir}" add 'example.c'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  # Mock ctags that always fails
  cat >"${mock_dir}/ctags" <<'MOCK'
#!/bin/bash
cat > /dev/null  # consume stdin
exit 1
MOCK
  chmod +x "${mock_dir}/ctags"

  local original_path="${PATH}"
  PATH="${mock_dir}:${PATH}"

  cd "${repo_dir}"

  run git::ctags::generate

  PATH="${original_path}"

  assert_failure
}

# bats test_tags=function::git::ctags::generate
@test "git::ctags::generate passes extra flags to ctags" {
  local mock_dir="${BATS_TEST_TMPDIR}/bin"
  local repo_dir="${BATS_TEST_TMPDIR}/repo"

  mkdir -p "${mock_dir}"
  git init "${repo_dir}"

  touch "${repo_dir}/example.c"
  git -C "${repo_dir}" add 'example.c'
  git -C "${repo_dir}" \
    -c user.name=test -c user.email=test \
    commit -m 'initial'

  # Mock ctags: verify custom flag is present
  cat >"${mock_dir}/ctags" <<'MOCK'
#!/bin/bash
cat > /dev/null  # consume stdin
found_custom=0
outfile=""
for arg in "$@"; do
  if [[ "${arg}" == '--languages=+Ruby' ]]; then
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
fi
if [[ "${found_custom}" -ne 1 ]]; then
  echo "ERROR: custom flag not passed" >&2
  exit 1
fi
exit 0
MOCK
  chmod +x "${mock_dir}/ctags"

  local original_path="${PATH}"
  PATH="${mock_dir}:${PATH}"

  cd "${repo_dir}"

  run git::ctags::generate '--languages=+Ruby'

  PATH="${original_path}"

  assert_success
}
