#!/usr/bin/env pwsh

function Test-FileContainsBOM {
  [CmdletBinding()]
  param (
    [Parameter()]
    [string]
    $Path
  )

  $fullPath = (Get-Item $Path)
  $contents = new-object byte[] 3
  $stream = [System.IO.File]::OpenRead($fullPath.FullName)
  $stream.Read($contents, 0, 3) | Out-Null
  $stream.Close()
  return $contents[0] -eq 0xEF -and $contents[1] -eq 0xBB -and $contents[2] -eq 0xBF
}

function Test-StagedFilesContainBOM {
  $extensions = @(
    '*.cs', '*.csx', '*.vb', '*.vbx',
    '*.sln',
    '*.csproj', '*.vbproj', '*.vcxproj', '*.vcxproj.filters', '*.proj', '*.projitems', '*.shproj',
    '*.json', '*.yml', '*.config', '*.props', '*.targets', '*.nuspec', '*.resx', '*.ruleset',
    '*.xml', '*.axml', '*.xaml',
    '*.md',
    '*.htm', '*.html', '*.js', '*.ts', '*.css', '*.scss', '*.less',
    '.editorconfig',
    '.gitignore',
    '*.ps1',
    '*.plist',
    '*.storyboard'
  )

  $extensionsRegex = "^($($extensions -join '|' -replace '\.', '\.' -replace '\*', '.*'))$"
  $stagedFiles = @(git diff --cached --name-only --diff-filter=ACM | Get-Item)
  $files = $stagedFiles.Where( { $_.Name -match $extensionsRegex }) | `
    Select-Object -ExpandProperty FullName | `
    Resolve-Path -Relative

  $response = @{
    status = 0
    files = @()
  }

  foreach ($file in $files) {
    if (Test-FileContainsBOM $file) {
      $response.status = 1
      $response.files += $file
    }
  }

  return $response
}

# Check for byte-order marker
function Test-CommitHasNoBOM {
  $testName = "Has No BOM "
  $outputWidth = 80 - $testName.Length

  Write-Host $testName -NoNewline

  $response = (Test-StagedFilesContainBOM)

  if ($response.status -eq 0) {
    Write-Host " Passed".PadLeft($outputWidth, '.') -ForegroundColor Green
  } else {
    Write-Host " Failed".PadLeft($outputWidth, '.') -ForegroundColor Red
  }

  foreach ($file in $response.files) {
    Write-Host "file '$file' starts with a Unicode BOM. Please remove the BOM and re-add the file for commit"
  }

  exit $response.status
}

Test-CommitHasNoBOM
