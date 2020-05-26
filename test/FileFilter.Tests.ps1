using namespace System.Diagnostics.CodeAnalysis
using module '..\git-friends\src\FileFilter.psm1'
using module '.\TestHelper.psm1'

Describe 'FileFilter' {
  Context 'is empty' {
    BeforeEach {
      [SuppressMessage('PSReviewUnusedParameter', 'filter')]
      $filter = [FileFilter]::new()
    }

    It '#List' {
      $filter.List() | Should -Be @()
    }

    It '#Count' {
      $filter.Count() | Should -Be 0
    }

    It '#InclusionsFilter' {
      $filter.InclusionsFilter() | Should -Be @()
    }

    It '#ExclusionsFilter' {
      $filter.ExclusionsFilter() | Should -Be @()
    }

    It '#Equals' {
      $filter | Should -Be $filter
    }

    It '.op_Addition' {
      $include = @('foo', 'bar', 'qux')
      $exclude = @('xuq', 'rab', 'oof')
      $other = [FileFilter]::new($include, $exclude)
      $filter += $other
      $filter | Should -Be $other
    }
  }

  Context 'is not empty' {
    BeforeEach {
      $include = @('foo', 'bar', 'qux')
      $exclude = @('xuq', 'rab', 'oof')

      [SuppressMessage('PSReviewUnusedParameter', 'filter')]
      $filter = [FileFilter]::new($include, $exclude)
    }

    It '#List' {
      $filter.List() | Should -Be @(':foo', ':bar', ':qux', ':!:xuq', ':!:rab', ':!:oof')
    }

    It '#Count' {
      $filter.Count() | Should -Be 6
    }

    It '#InclusionsFilter' {
      $filter.InclusionsFilter() | Should -Be @(':foo', ':bar', ':qux')
    }

    It '#ExclusionsFilter' {
      $filter.ExclusionsFilter() | Should -Be @(':!:xuq', ':!:rab', ':!:oof')
    }

    It '#Equals' {
      $filter | Should -Be $filter
    }

    It '.op_Addition' {
      $include = @('foo', 'bar', 'qux')
      $exclude = @('xuq', 'rab', 'oof')

      $other = [FileFilter]::new($include, $exclude)
      $filter += $other
      $filter | Should -Be $other

      $other = [FileFilter]::new(@('baz', 'foo'), @('foobar', 'rab'))
      $filter += $other
      $filter | Should -Not -Be $other
      $filter.Inclusions | Should -Be @('foo', 'bar', 'qux', 'baz')
      $filter.Exclusions | Should -Be @('xuq', 'rab', 'oof', 'foobar')
    }
  }
}
