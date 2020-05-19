param([switch] $WhatIf = $false, [switch] $Force = $false, [switch] $Verbose = $false)

$installDir = Split-Path $MyInvocation.MyCommand.Path -Parent

if ($whatIf) {
  Write-Output "Import-Module $installDir/git-friends/git-friends.psd1 -Force:$Force -Verbose:$Verbose"
  exit
}

if ($Force -and (Get-Module git-friends)) {
  Remove-Module git-friends -Force -Verbose:$Verbose
}

Import-Module $installDir/git-friends/git-friends.psd1 -Force:$Force -Verbose:$Verbose
