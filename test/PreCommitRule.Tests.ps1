using namespace System.Diagnostics.CodeAnalysis
using module '..\git-friends\src\hooks\pre_commit\Rule.psm1'

Describe 'PreCommitRule' {
  function Test-DummyBlock { }

  Mock Write-Host { } -ModuleName Rule

  BeforeEach {
    [SuppressMessage('PSReviewUnusedParameter', 'rule')]
    $rule = [PreCommitRule]::new(
      'name',
      'how-to-fix',
      $false, { Test-DummyBlock }
    )
  }

  Context 'was skipped' {
    BeforeEach {
      $result = [PreCommitRuleResult]::new({
        param($result)
        $result.Status = $null
      })

      [SuppressMessage('PSReviewUnusedParameter', 'report')]
      $report = [PreCommitRuleReport]::new('name', $result, 'how-to-fix')

      Mock Test-DummyBlock {
        return $result
      }

      $rule.Skip = $true
    }

    It '#Run' {
      $rule.Run() | Should -Be $report
      Assert-MockCalled Test-DummyBlock 0 -Scope It
    }

    It '#RunAndReport' {
      $rule.RunAndReport() | Should -Be 0
      Assert-MockCalled Test-DummyBlock 0 -Scope It
      Assert-MockCalled Write-Host -Exactly 1 -Scope It -ModuleName Rule
    }
  }

  Context 'was run' {
    Context 'and failed' {
      BeforeEach {
        $result = [PreCommitRuleResult]::new({
          param($result)
          $result.Status = 1
        })

        [SuppressMessage('PSReviewUnusedParameter', 'report')]
        $report = [PreCommitRuleReport]::new('name', $result, 'how-to-fix')

        Mock Test-DummyBlock {
          return $result
        }
      }

      It '#Run' {
        $rule.Run() | Should -Be $report
        Assert-MockCalled Test-DummyBlock -Exactly 1 -Scope It
      }

      It '#RunAndReport' {
        $rule.RunAndReport() | Should -Be 1
        Assert-MockCalled Test-DummyBlock -Exactly 1 -Scope It
        Assert-MockCalled Write-Host -Exactly 3 -Scope It -ModuleName Rule
      }
    }

    Context 'and passed' {
      BeforeEach {
        $result = [PreCommitRuleResult]::new({
          param($result)
          $result.Status = 0
        })

        [SuppressMessage('PSReviewUnusedParameter', 'report')]
        $report = [PreCommitRuleReport]::new('name', $result, 'how-to-fix')

        Mock Test-DummyBlock {
          return $result
        }
      }

      It '#Run' {
        $rule.Run() | Should -Be $report
        Assert-MockCalled Test-DummyBlock -Exactly 1 -Scope It
      }

      It '#RunAndReport' {
        $rule.RunAndReport() | Should -Be 0
        Assert-MockCalled Test-DummyBlock -Exactly 1 -Scope It
        Assert-MockCalled Write-Host -Exactly 1 -Scope It -ModuleName Rule
      }
    }
  }
}
