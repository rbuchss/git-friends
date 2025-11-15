#!/bin/bash
# shellcheck source=/dev/null
source "${BASH_SOURCE[0]%/*}/logger.sh"

function git::format::newline {
  local mode="${1:-staged}"

  case "${mode}" in
    all | tracked)
      git::format::newline::all
      ;;
    dc | staged)
      git::format::newline::staged
      ;;
    df | changed)
      git::format::newline::changed
      ;;
    *)
      git::logger::error "Invalid mode: '${mode}'. Choices [all(tracked), dc(staged), df(changed)]"
      return 1
      ;;
  esac
}

function git::format::newline::all {
  git::format::__newline_from_command__ \
    'tracked' \
    git ls-files
}

function git::format::newline::staged {
  git::format::__newline_from_command__ \
    'staged' \
    git diff --cached --name-only --diff-filter=ACM
}

function git::format::newline::changed {
  git::format::__newline_from_command__ \
    'changed' \
    git diff HEAD --name-only --diff-filter=ACM
}

function git::format::newline::process {
  local \
    file \
    status=0

  if (( $# == 0 )); then
    git::logger::error 'No files specified'
    return 1
  fi

  for file in "$@"; do
    if [[ -L "${file}" ]]; then
      git::logger::debug "Skipping symlink: '${file}'"
      continue
    fi

    if git::format::__is_in_submodule__ "${file}"; then
      git::logger::debug "Skipping submodule file: '${file}'"
      continue
    fi

    if [[ ! -f "${file}" ]]; then
      git::logger::warning "File does not exist: '${file}'"
      status=1
      continue
    fi

    if [[ ! -r "${file}" ]]; then
      git::logger::error "Cannot read file: '${file}'"
      status=1
      continue
    fi

    if [[ ! -w "${file}" ]]; then
      git::logger::error "Cannot write to file: '${file}'"
      status=1
      continue
    fi

    # Check if file is empty
    if [[ ! -s "${file}" ]]; then
      git::logger::debug "File is empty, skipping: '${file}'"
      continue
    fi

    # Check if file ends with a newline
    # Using tail -c1 to get the last byte of the file
    if [[ "$(tail -c1 "${file}" 2>/dev/null)" != "" ]]; then
      git::logger::info "Adding trailing newline to: '${file}'"

      # Add a newline to the end of the file
      echo >> "${file}"
    else
      git::logger::debug "File already has trailing newline: '${file}'"
    fi
  done

  return "${status}"
}

function git::format::__is_in_submodule__ {
  local \
    file="$1" \
    submodule_path

  # Get list of submodule paths
  while IFS= read -r submodule_path; do
    # Check if file path starts with submodule path
    if [[ "${file}" == "${submodule_path}"/* ]] \
      || [[ "${file}" == "${submodule_path}" ]]; then
        return 0
    fi
  done < <(
    git config \
      --file .gitmodules \
      --get-regexp path \
      | awk '{print $2}' 2>/dev/null
  )

  return 1
}

function git::format::__newline_from_command__ {
  local \
    file_type="$1" \
    files=() \
    file_count \
    file

  shift

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    git::logger::error -c 2 'Not in a git repository'
    return 1
  fi

  git::logger::info -c 2 "Getting all ${file_type} files..."

  while IFS= read -r file; do
    files+=("${file}")
  done < <("$@")

  file_count="${#files[@]}"

  if (( file_count == 0 )); then
    git::logger::warning -c 2 "No ${file_type} files found"
    return 0
  fi

  git::logger::info -c 2 "Processing ${file_count} ${file_type} file(s)..."

  git::format::newline::process "${files[@]}"
}
