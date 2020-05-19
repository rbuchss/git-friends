#!/usr/bin/env pwsh

Import-Module $env:HOME/.git-friends/git-friends.psd1

exit (Test-CommitHasNoBOM @args)
