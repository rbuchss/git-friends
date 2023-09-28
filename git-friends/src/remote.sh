#!/bin/bash

function git::remote::default_branch() {
  local remote_name="${1:-origin}"
  # This way is more relable but slow due to the network call:
  # git remote show "${remote_name}" | sed -n '/HEAD branch/s/.*: //p'
  #
  # This version is faster since it uses the git cached version. However, due to this this can fail.
  # To avoid this we can sync this symbolic ref from upstream using:
  # $ git remote set-head origin --auto.
  # This updates both what is seen in git remote show and the symbolic ref referenced here.
  git symbolic-ref "refs/remotes/${remote_name}/HEAD" \
    | sed "s@^refs/remotes/${remote_name}/@@"
}
