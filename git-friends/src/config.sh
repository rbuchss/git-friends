#!/bin/bash

function git::config::group() {
  local group="$1"
  git config --get-regexp "^${group}"
}

function git::config::aliases() {
  local search="$1"

  git::config::group 'alias' \
    | sort \
    | awk -v search="${search}" 'BEGIN {
      print "ALIAS", "#", "COMMAND"
      print "-----", "#", "-------"
    }
    {
      gsub("alias\.", "", $1)
      first = $1
      $1 = ""
      gsub("^[[:space:]]+", "")
      if (first ~ search || $0 ~ search) {
        print first, "#", $0
      }
    }' \
    | column -t -s '#'
}
