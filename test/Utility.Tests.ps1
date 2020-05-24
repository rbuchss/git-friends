using namespace System.Diagnostics.CodeAnalysis
using module '..\git-friends\src\Utility.psm1'
using module '.\TestHelper.psm1'

Describe 'Utility' {
  Context 'Merge-Hashtables' {
    BeforeEach {
      [SuppressMessage('PSReviewUnusedParameter', 'h1')]
      $h1 = @{a = 9; b = 8; c = 7}

      [SuppressMessage('PSReviewUnusedParameter', 'h2')]
      $h2 = @{b = 6; c = 5; d = 4}

      [SuppressMessage('PSReviewUnusedParameter', 'h3')]
      $h3 = @{c = 3; d = 2; e = 1}

      [SuppressMessage('PSReviewUnusedParameter', 'h4')]
      $h4 = @{ b = @(1, 2, 3) }
    }

    It 'merges two hashtables' {
      $expected = @{
        a = 9
        b = @(8, 6)
        c = @(7, 5)
        d = 4
      }
      $result = ($h1, $h2 | Merge-Hashtables)
      $result | Should -HaveDeepEquality $expected
    }

    It 'merges three hashtables' {
      $expected = @{
        a = 9
        b = @(8, 6)
        c = @(7, 5, 3)
        d = @(4, 2)
        e = 1
      }
      $result = ($h1, $h2, $h3 | Merge-Hashtables)
      $result | Should -HaveDeepEquality $expected
    }

    It 'merges four hashtables' {
      $expected = @{
        a = 9
        b = @(8, 6, 1, 2, 3)
        c = @(7, 5, 3)
        d = @(4, 2)
        e = 1
      }
      $result = ($h1, $h2, $h3, $h4 | Merge-Hashtables)
      $result | Should -HaveDeepEquality $expected
    }

    It 'merges and sorts four hashtables' {
      $expected = @{
        a = 9
        b = @(1, 2, 3, 6, 8)
        c = @(3, 5, 7)
        d = @(2, 4)
        e = 1
      }
      $result = ($h1, $h2, $h3, $h4 | Merge-Hashtables { $args | Sort-Object })
      $result | Should -HaveDeepEquality $expected

    }

    It 'merges four hashtables into strings' {
      $expected = @{
        a = '9'
        b = '86123'
        c = '753'
        d = '42'
        e = '1'
      }
      $result = ($h1, $h2, $h3, $h4 | Merge-Hashtables { -join $args })
      $result | Should -HaveDeepEquality $expected
    }

    It 'merges four hashtables into single element arrays of strings' {
      $expected = @{
        a = @('9')
        b = @('86123')
        c = @('753')
        d = @('42')
        e = @('1')
      }
      $result = ($h1, $h2, $h3, $h4 | Merge-Hashtables { ,@(-join $args) })
      $result | Should -HaveDeepEquality $expected
    }

    It 'merges four hashtables into averages' {
      $expected = @{
        a = 9
        b = 4
        c = 5
        d = 3
        e = 1
      }
      $result = ($h1, $h2, $h3, $h4 | Merge-Hashtables {
        [int]($args | Measure-Object -Average).Average
      })
      $result | Should -HaveDeepEquality $expected
    }

    It 'merges four hashtables into sums' {
      $expected = @{
        a = 9.0
        b = 20.0
        c = 15.0
        d = 6.0
        e = 1.0
      }
      $result = ($h1, $h2, $h3, $h4 | Merge-Hashtables {
        ($args | Measure-Object -Sum).Sum
      })
      $result | Should -HaveDeepEquality $expected
    }
  }
}
