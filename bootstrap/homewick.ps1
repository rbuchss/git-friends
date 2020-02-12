<#
  Creates symlinks for all files in repo home dir in $HOME
#>

$repoPath = (Get-Item $PSScriptRoot).Parent
$repoName = $repoPath.BaseName

$repoHome = if (Test-Path (Join-Path $repoPath "windows-home")) {
  (Join-Path $repoPath "windows-home")
} elseif (Test-Path (Join-Path $repoPath "home")) {
  (Join-Path $repoPath "home")
} else {
  throw "Repo has neither 'home' nor 'windows-home' directories required for linking!"
}

$force = $true

Write-Host "linking home files from '$repoName' ..." -ForegroundColor Yellow

Get-ChildItem $repoHome |
Foreach-Object {
  $linkPath = "$HOME\$($_.Name)"

  if (Test-Path $linkPath) {
    Write-Host "exists:`t`t'$linkPath' -> '$_'" -ForegroundColor Blue 
    if ($force) {
      Write-Host "overwrite?`t'$linkPath' -> '$_'" -ForegroundColor Red
      New-Item -ItemType SymbolicLink -Path $HOME -Name $_.Name -Value $_ -Confirm -Force > $null
    }
  } else {
    Write-Host "linking:`t`t'$linkPath' -> '$_'" -ForegroundColor Green
    New-Item -ItemType SymbolicLink -Path $HOME -Name $_.Name -Value $_ > $null
  }
}