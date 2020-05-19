#!/usr/bin/env pwsh

using module '.\ProjectType.psm1'

class ProjectTypes {
  static [ProjectTypes] $Instance
  [ProjectType[]] $Collection

  static [ProjectTypes] Shared() {
    if ($null -eq [ProjectTypes]::Instance) {
      [ProjectTypes]::Instance = [ProjectTypes]::new()
    }
    return [ProjectTypes]::Instance
  }

  static [ProjectType] Factory() {
    $name = @(git config --get 'git-friends.project-type')

    if ([string]::IsNullOrEmpty($name)) {
      $name = 'undefined'
    }

    return [ProjectTypes]::Shared().GetType($name)
  }

  ProjectTypes() {
    $blob = (Get-Content $env:HOME/.git-friends/config/project_types.json -Raw `
      | ConvertFrom-Json).Types

    foreach ($element in $blob) {
      $this.Collection += [ProjectType]::new($element)
    }

    foreach ($element in $this.Collection) {
      $element.Extensions = $this.ResolveExtensions($element)
    }
  }

  [ProjectType] GetType([string] $name) {
    return $this.Collection.Where({ $_.Name -eq $name }) | Select-Object -First 1
  }

  hidden [string[]] ResolveExtensions([ProjectType] $projectType) {
    $extensions = $projectType.Extensions

    foreach ($parent in $projectType.Parents) {
      $extensions += $this.GetType($parent).Extensions
    }

    return $extensions | Sort-Object | Get-Unique
  }
}
