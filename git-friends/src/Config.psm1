#!/usr/bin/env pwsh

using module '.\Utility.psm1'

class Config {
  [hashtable] $Metadata

  Config() {
    $this.Init(@{})
  }

  Config([hashtable] $options) {
    $this.Init($options)
  }

  [object] Get([string[]] $keys) {
    $result = $this.Metadata

    foreach ($key in $keys) {
      if (-not $result.ContainsKey($key)) {
        return $null
      }
      $result = $result.$key
    }

    return $result
  }

  hidden Init([hashtable] $options) {
    $file = $options.file
    $group = $options.group

    $flags = (-not [string]::IsNullOrEmpty($file)) `
      ? @('--file', $file)
      : @()

    $flags += (-not [string]::IsNullOrEmpty($group)) `
      ? @('--get-regexp', "^$group")
      : @('--get-regexp', '^.+')

    $response = (git config $flags) # TODO check exit status
    $this.Metadata = $this.ParseConfig($response)

    if (-not [string]::IsNullOrEmpty($group)) {
      foreach ($section in $group.Split('.')) {
        if (-not $this.Metadata.ContainsKey($section)) {
          break
        }
        $this.Metadata= $this.Metadata.$section
      }
    }
  }

  [hashtable] ParseConfig($config) {
    $dictionary = @{}

    switch -regex ($config) {
      '^(?<section>[^. ]+)\.(?<keyValue>.+)$' {
        $section = $matches.section
        $keyValue = $matches.keyValue

        if (-not $dictionary.ContainsKey($section)) {
          $dictionary[$section] = @{}
        }

        foreach ($pair in $this.ParseConfig($keyValue).GetEnumerator()) {
          $key = $pair.Key
          $value = $pair.Value

          $dictionary[$section][$key] = if ($dictionary[$section].ContainsKey($key)) {
            $current = $dictionary[$section][$key]

            if ($current -is [hashtable] -and $value -is [hashtable]) {
              ($current, $value | Merge-Hashtables)
            } elseif ($value -is [hashtable]) {
              @{ '_' = $current } + $value
            } else {
              @($current) + $value
            }
          } else {
            $value
          }
        }
      }

      '^(?<key>[^. ]+) +(?<value>.+)$' {
        $dictionary[$matches.Key] = $matches.Value
      }
    }

    return $dictionary
  }
}
