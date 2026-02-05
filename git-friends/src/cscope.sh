#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/config.sh"
source "${BASH_SOURCE[0]%/*}/logger.sh"

function git::cscope::generate {
  local cmd_path \
    tmp_file \
    extra_flags=("$@")

  if ! cmd_path="$(command -v cscope 2>/dev/null)"; then
    git::logger::error "command 'cscope' could not be found"
    return 1
  fi

  if ! tmp_file="$(git::dir "git-friends/cscope.out.$$")"; then
    git::logger::error 'git-dir could not be found'
    return 1
  fi

  if [[ ! -d "${tmp_file%/*}" ]] \
    && ! mkdir -p "${tmp_file%/*}"; then
      git::logger::error "cannot make cscope directory: '${tmp_file%/*}'"
      return 1
  fi

  git::logger::info "Using: '${cmd_path}'"

  # -b: just build
  # -q: create inverted index
  if git::cscope::files \
    | cscope -i - \
    -f "${tmp_file}" \
    -b -q -v \
    "${extra_flags[@]}"; then
      for file in "${tmp_file}"*; do
        mv -v "${file}" "${file//.$$/}"
      done
      git::logger::info 'Success'
      return
  fi

  git::logger::error "'git ls-files' or 'cscope' had errors; aborting"
  rm -f "${tmp_file}"
  return 1
}

function git::cscope::files {
  # TODO is filtering even required?
  git ls-files -- \
    ':*.py' \
    ':*.java' \
    ':*.properties' \
    ':*.c' \
    ':*.C' \
    ':*.h' \
    ':*.H' \
    ':*.cc' \
    ':*.cpp' \
    ':*.c++' \
    ':*.cp' \
    ':*.cxx' \
    ':*.hh' \
    ':*.hpp' \
    ':*.h++' \
    ':*.hp' \
    ':*.hxx' \
    ':*.ino'
}
