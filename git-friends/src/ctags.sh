#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/config.sh"

function git::ctags::generate() {
  local cmd_path \
    tmp_file \
    tags_file \
    extra_flags=("$@")

  if ! cmd_path="$(command -v ctags 2>/dev/null)"; then
    >&2 echo "ERROR: ${FUNCNAME[0]}: command 'ctags' could not be found"
    return 1
  fi

  if [[ -f '.ctagsignore' ]]; then
    extra_flags+=('--exclude=@.ctagsignore')
  fi

  if ! tmp_file="$(git::dir "git-friends/tags.$$")"; then
    >&2 echo "ERROR: ${FUNCNAME[0]}: git-dir could not be found"
    return 1
  fi

  tags_file="${tmp_file%.*}"

  if [[ ! -d "${tmp_file%/*}" ]] \
    && ! mkdir -p "${tmp_file%/*}"; then
      >&2 echo "ERROR: ${FUNCNAME[0]}: cannot make ctags directory: '${tmp_file%/*}'"
      return 1
  fi

  echo "Using: ${cmd_path}"

  if git ls-files \
    | ctags -L - \
    -f "${tmp_file}" \
    --c++-kinds=+p \
    --c-kinds=+p \
    --exclude=.git \
    --extra=+fq \
    --fields=+iaS \
    --tag-relative \
    --totals \
    --verbose \
    "${extra_flags[@]}"; then
      mv -v "${tmp_file}" "${tags_file}"
      echo "${FUNCNAME[0]}: Success"
      return
  fi

  >&2 echo "ERROR: ${FUNCNAME[0]}: 'git ls-files' or 'ctags' had errors; aborting"
  rm -f "${tmp_file}"
  return 1
}
