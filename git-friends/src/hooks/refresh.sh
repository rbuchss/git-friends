#!/bin/bash

function git::hooks::refresh {
  local hooks=(.git/hooks/*)

  if (( "${#hooks[@]}" != 0 )); then
    echo 'Clearing out old hooks:'

    for hook in "${hooks[@]}"; do
      echo " - remove: ${hook}"
      rm -r "${hook}" || {
        >&2 echo "ERROR: ${FUNCNAME[0]} failed: cannot remove '${hook}'"
        return 1
      }
    done
  fi

  echo 'Loading current hooks:'

  git init

  for hook in .git/hooks/*; do
    echo " - add: ${hook}"
  done
}
