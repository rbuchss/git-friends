using namespace System.Diagnostics.CodeAnalysis
using module '..\git-friends\src\Config.psm1'
using module '.\TestHelper.psm1'

Describe 'Config' {
  Context '#new' {
    It 'parses the git-friends config group' {
      $expected = @{
        'literal-off' = 'off'
        'literal-yes' = 'yes'
        'literal-on' = 'on'
        'blarg' = 'blarg'
        'single-value' = 'yarp'
        'num-0' = '0'
        'literal-true' = 'true'
        'literal-false' = 'false'
        'num-1' = '1'
        'literal-no' = 'no'
        'in-fixture' = 'noop'
        'multi-value' = @('yarp', 'carp', 'narp')
        'pre-commit' = @{
          'disable' = 'false'
          'skip' = @(
            'pom.xml',
            'junit.java',
            'Runit.java',
            'Runit2.java'
          )
        }
      }
      $config = [Config]::new(@{
        file = './test/fixtures/gitconfig'
        group = 'git-friends'
      })
      $config.Metadata | Should -HaveDeepEquality $expected
      $config.Get('literal-off') | Should -Be 'off'
      $config.Get('missing-key') | Should -BeNullorEmpty
      $config.Get(@('pre-commit', 'skip')) | Should -Be @(
        'pom.xml',
        'junit.java',
        'Runit.java',
        'Runit2.java'
      $config.Get(@('pre-commit', 'missing-key')) | Should -BeNullorEmpty
      )
    }

    It 'parses the git-friends.pre-commit config group' {
      $expected = @{
        disable = 'false'
        skip = @(
          'pom.xml',
          'junit.java',
          'Runit.java',
          'Runit2.java'
        )
      }
      $config = [Config]::new(@{
        file = './test/fixtures/gitconfig'
        group = 'git-friends.pre-commit'
      })
      $config.Metadata | Should -HaveDeepEquality $expected
    }
  }
}
