using namespace System.Diagnostics.CodeAnalysis
using module '..\git-friends\src\FileFilterTemplate.psm1'
using module '..\git-friends\src\FileFilter.psm1'
using module '.\TestHelper.psm1'

Describe 'FileFilterTemplate' {
  BeforeEach {
    [SuppressMessage('PSReviewUnusedParameter', 'undefinedTemplate')]
    $undefinedTemplate = [FileFilterTemplate]::GetTemplate('undefined')

    [SuppressMessage('PSReviewUnusedParameter', 'commonTemplate')]
    $commonTemplate = [FileFilterTemplate]::GetTemplate('common')

    [SuppressMessage('PSReviewUnusedParameter', 'csharpTemplate')]
    $csharpTemplate = [FileFilterTemplate]::GetTemplate('c#')
  }

  Context '.GetTemplate' {
    It 'returns undefined template if name is $null' {
      $template = [FileFilterTemplate]::GetTemplate($null)
      $template | Should -Be $undefinedTemplate
    }

    It 'returns undefined template if name is blank' {
      $template = [FileFilterTemplate]::GetTemplate('')
      $template | Should -Be $undefinedTemplate
    }

    It 'returns undefined template if name is not found' {
      $template = [FileFilterTemplate]::GetTemplate('does-not-exist')
      $template | Should -Be $undefinedTemplate
    }

    It 'returns template if name is found' {
      $template = [FileFilterTemplate]::GetTemplate('c#')
      $template | Should -Not -Be $undefinedTemplate
      $template.Name | Should -Be 'c#'
      $template.Parents | Should -Be @('common')
      $template | Should -Be $csharpTemplate
    }

    It 'returns template with properly resolved inheritance' {
      $template = [FileFilterTemplate]::GetTemplate('xamarin')
      $template | Should -Not -Be $undefinedTemplate
      $template.Name | Should -Be 'xamarin'
      $template.Parents | Should -Be @('c#')

      foreach ($element in ($commonTemplate.Inclusions + $csharpTemplate.Inclusions)) {
        $template.Inclusions | Should -Contain $element
      }

      foreach ($element in ($commonTemplate.Exclusions + $csharpTemplate.Exclusions)) {
        $template.Exclusions | Should -Contain $element
      }
    }
  }

  Context '.Factory' {
    BeforeEach {
      [SuppressMessage('PSReviewUnusedParameter', 'includeAllFilter')]
      $includeAllFilter = [FileFilter]::new(@('*'), @())

      [SuppressMessage('PSReviewUnusedParameter', 'commonFilter')]
      $commonFilter = [FileFilter]::new(@(
        "*.md",
        ".editorconfig",
        ".gitignore"
      ), @())
    }

    It 'returns include all filter if name is $null' {
      $filter = [FileFilterTemplate]::Factory($null)
      $filter | Should -Be $includeAllFilter
    }

    It 'returns include all filter if name is blank' {
      $filter = [FileFilterTemplate]::Factory('')
      $filter | Should -Be $includeAllFilter
    }

    It 'returns include all filter if name is not found' {
      $filter = [FileFilterTemplate]::Factory('does-not-exist')
      $filter | Should -Be $includeAllFilter
    }

    It 'returns proper filter if name is found' {
      $filter = [FileFilterTemplate]::Factory('common')
      $filter | Should -Be $commonFilter
    }
  }
}
