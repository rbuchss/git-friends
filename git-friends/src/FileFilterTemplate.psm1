#!/usr/bin/env pwsh

using module '.\FileFilter.psm1'

class FileFilterTemplate {
  static [FileFilterTemplate[]] $Templates

  [string] $Name
  [string[]] $Parents
  [string[]] $Inclusions
  [string[]] $Exclusions

  FileFilterTemplate([PSObject] $obj) {
    $this.Name = $obj.Name
    $this.Parents = $obj.Parents
    $this.Inclusions = $obj.Include
    $this.Exclusions = $obj.Exclude
  }

  [FileFilter] Build() {
    return [FileFilter]::new($this.Inclusions, $this.Exclusions)
  }

  [bool] Equals($other) {
    if ($this.Name -eq $other.Name `
        -and (Compare-Object -ReferenceObject $this.Parents `
          -DifferenceObject $other.Parents).Length -eq 0 `
        -and (Compare-Object -ReferenceObject $this.Inclusions `
          -DifferenceObject $other.Inclusions).Length -eq 0 `
        -and (Compare-Object -ReferenceObject $this.Exclusions `
          -DifferenceObject $other.Exclusions).Length -eq 0) {
      return $true
    }
    return $false
  }

  static FileFilterTemplate() {
    $blob = (Get-Content $env:HOME/.git-friends/config/file_filters.json -Raw `
      | ConvertFrom-Json).Templates

    foreach ($element in $blob) {
      [FileFilterTemplate]::Templates += [FileFilterTemplate]::new($element)
    }

    foreach ($element in [FileFilterTemplate]::Templates) {
      $element.Inclusions = [FileFilterTemplate]::ResolveInclusions($element)
      $element.Exclusions = [FileFilterTemplate]::ResolveExclusions($element)
    }
  }

  static [FileFilter] Factory([string] $name) {
    return [FileFilterTemplate]::GetTemplate($name).Build()
  }

  static [FileFilterTemplate] GetTemplate([string] $templateName) {
    if ([string]::IsNullOrEmpty($templateName) `
      -or [FileFilterTemplate]::Templates.Name -NotContains $templateName) {
      $templateName = 'undefined'
    }

    return ([FileFilterTemplate]::Templates.Where({ $_.Name -eq $templateName }) `
      | Select-Object -First 1)
  }

  hidden static [string[]] ResolveInclusions([FileFilterTemplate] $template) {
    $include = $template.Inclusions

    foreach ($parent in $template.Parents) {
      $include += [FileFilterTemplate]::GetTemplate($parent).Inclusions
    }

    return ($include.Count -gt 0) `
      ? ($include | Sort-Object -Unique)
      : $include
  }

  hidden static [string[]] ResolveExclusions([FileFilterTemplate] $template) {
    $exclude = $template.Exclusions

    foreach ($parent in $template.Parents) {
      $exclude += [FileFilterTemplate]::GetTemplate($parent).Exclusions
    }

    return ($exclude.Count -gt 0) `
      ? ($exclude | Sort-Object -Unique)
      : $exclude
  }
}
