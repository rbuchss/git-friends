#!/usr/bin/env pwsh

. ~/.git-friends/src/hooks/pre_commit/test/no_bom.ps1

exit (Test-CommitHasNoBOM @args)
