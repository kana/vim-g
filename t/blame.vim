runtime plugin/g.vim

" For some reason 'shellredir' is set to '>' while running tests.
set shellredir=>%s\ 2>&1

describe ':G blame'
  after
    % bwipeout!
  end

  it 'can blame only a normal buffer'
    help

    redir => log
    G blame
    redir END
    let log = log[1:]

    " unnamed buffer + help = 2
    Expect winnr('$') == 2
    Expect log ==# 'g: Only a normal buffer can be blamed'
  end

  it 'cannot blame a file not tracked by Git'
    edit untracked

    redir => log
    G blame
    redir END
    let log = log[1:]

    " untracked file = 1
    Expect winnr('$') == 1
    Expect log ==# 'g: fatal: no such path ''untracked'' in HEAD'
  end

  it 'opens the blame viewer for the current buffer'
    edit t/fixture/example.md

    G blame

    " tracked file + blame viewer = 2
    Expect winnr('$') == 2
    Expect bufname('') ==# '[git blame] t/fixture/example.md'
    Expect getline(1, '$') ==# readfile('t/fixture/blame.1')
  end

  context 'viewer'
    before
      edit t/fixture/example.md
      G blame
    end

    it 'enables to show older content by pressing K'
      normal! 15G
      normal $K
      Expect getline(1, '$') ==# readfile('t/fixture/blame.2')

      normal! 12G
      normal $K
      Expect getline(1, '$') ==# readfile('t/fixture/blame.3')

      normal! 15G
      normal $K
      Expect getline(1, '$') ==# readfile('t/fixture/blame.4')
    end

    it 'is an error to K on an oldest line'
      normal! 1G

      redir => log
      normal $K
      redir END
      let log = log[1:]

      Expect log ==# 'g: fatal: no such path t/fixture/sample.md in 6d57cd86~'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.1')
    end

    it 'is an error to K on a non-blame line (though it is unlikely to occur)'
      1 put! ='foo'

      redir => log
      normal $K
      redir END
      let log = log[1:]

      Expect log ==# 'g: Cannot find the commit id for the current line'
      Expect getline(1, '$') ==# ['foo'] + readfile('t/fixture/blame.1')
    end
  end
end
