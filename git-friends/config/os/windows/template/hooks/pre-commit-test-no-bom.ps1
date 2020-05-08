#!/usr/bin/env pwsh

$ESC = [char]0x1B

$color = @{
  Error = "$ESC[0;91m";
  Warning = "$ESC[0;93m";
  Information = "$ESC[0;92m";
  Violation = "$ESC[0;31m";
  Off = "$ESC[0m"
}

function Test-FileContainsBOM {
  [CmdletBinding()]
  [OutputType([bool])]
  param (
    [Parameter()]
    [string]
    $Path
  )

  $fullPath = (Get-Item -Force $Path)
  $contents = new-object byte[] 3
  $stream = [System.IO.File]::OpenRead($fullPath.FullName)
  $stream.Read($contents, 0, 3) | Out-Null
  $stream.Close()
  return $contents[0] -eq 0xEF -and $contents[1] -eq 0xBB -and $contents[2] -eq 0xBF
}

function Test-StagedFilesContainBOM {
  # TODO have param/lookup for this?
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
  # TODO use git filtering here?
  $stagedFiles = @(git diff --cached --name-only --diff-filter=ACM | Get-Item -Force)
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
  $testName = 'Has No BOM'
  $outputWidth = 80 - $testName.Length

  $response = (Test-StagedFilesContainBOM)

  $result = '{0} {1}{2}{3}' -f `
    $testName,
    ($response.status -eq 0 ? $color['Information'] : $color['Error']),
    ($response.status -eq 0 ? ' Passed' : ' Failed').PadLeft($outputWidth, '.'),
    $color['Off']

  Write-Output $result

  if ($response.status -ne 0 ) {
    $header = '{0}{1} {2} found:{3}' -f `
      $color['Error'],
      $response.files.Count,
      ($response.files.Count -gt 1 ? 'violations' : 'violation'),
      $color['Off']

    Write-Output $header
    Write-Output $color['Violation']

    foreach ($file in $response.files) {
      Write-Output $file
    }

    $footer = '{0}{1}Please remove the {2} and re-add the {3} for commit:{4}' -f `
      "`n",
      $color['Error'],
      ($response.files.Count -gt 1 ? 'BOMs' : 'BOM'),
      ($response.files.Count -gt 1 ? 'files' : 'file'),
      $color['Off']

    Write-Output $footer
  }

  exit $response.status
}

Test-CommitHasNoBOM
