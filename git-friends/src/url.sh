#!/bin/bash

function git::url::parse() {
  sed -E 's#(git\@|https://)([^/:]+)(:|/)([^/]+)/(.+$)#'\\"$2"'#g' \
    <<< "$1"
}
