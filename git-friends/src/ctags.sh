#!/bin/bash
# shellcheck source=/dev/null
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/__module__.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/exec.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/config.sh"
source "${GIT_FRIENDS_MODULE_SRC_DIR:-${BASH_SOURCE[0]%/*}}/logger.sh"

git::__module__::load || return 0

function git::ctags::generate {
  local \
    cmd_path \
    tmp_file \
    tags_file \
    extra_flags=("$@")

  if ! cmd_path="$(command -v ctags 2>/dev/null)"; then
    git::logger::error "command 'ctags' could not be found"
    return 1
  fi

  if [[ -f '.ctagsignore' ]]; then
    extra_flags+=('--exclude=@.ctagsignore')
  fi

  if ! tmp_file="$(git::dir "git-friends/tags.$$")"; then
    git::logger::error 'git-dir could not be found'
    return 1
  fi

  tags_file="${tmp_file%.*}"

  if [[ ! -d "${tmp_file%/*}" ]] \
    && ! mkdir -p "${tmp_file%/*}"; then
    git::logger::error "cannot make ctags directory: '${tmp_file%/*}'"
    return 1
  fi

  git::logger::info "Using: '${cmd_path}'"

  if git::exec ls-files \
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
    git::logger::info 'Success'
    return
  fi

  git::logger::error "'git ls-files' or 'ctags' had errors; aborting"
  rm -f "${tmp_file}"
  return 1
}

function git::ctags::__export__ {
  export -f git::ctags::generate
}

# KCOV_EXCL_START
function git::ctags::__recall__ {
  export -fn git::ctags::generate
}
# KCOV_EXCL_STOP

git::__module__::export
