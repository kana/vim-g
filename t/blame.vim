call vspec#hint({'scope': 'g#_scope()'})

runtime plugin/g.vim

" For some reason 'shellredir' is set to '>' while running tests.
set shellredir=>%s\ 2>&1

" Sometimes it's necessary to manually break undo while running tests.
function! s:break_undo()
  let &l:undolevels = &l:undolevels
endfunction

describe ':G blame'
  after
    % bwipeout!
    ResetContext
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
    Expect &l:modifiable to_be_false
  end

  context 'viewer'
    it 'enables to show the commit for the current line'
      edit t/fixture/example.md
      G blame

      let ids = []
      call Set('s:show', {commit_id -> add(ids, commit_id)})

      normal! 1G$
      normal K
      Expect ids ==# ['6d57cd86']

      normal! 9G$
      normal K
      Expect ids ==# ['6d57cd86', '577278fb']
    end

    it 'enables to blame older content'
      edit t/fixture/example.md
      G blame

      normal! 15G$
      normal o
      Expect bufname('') ==# '[git blame] 523d0005~ t/fixture/example.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.2')

      normal! 12G$
      normal o
      Expect bufname('') ==# '[git blame] 577278fb~ t/fixture/sample.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.3')

      normal! 15G$
      normal o
      Expect bufname('') ==# '[git blame] 5035bdbf~ t/fixture/sample.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.4')
    end

    it 'is an error to blame older content on an oldest line'
      edit t/fixture/example.md
      G blame

      normal! 1G$

      redir => log
      normal o
      redir END
      let log = log[1:]

      Expect log ==# 'g: fatal: no such path t/fixture/sample.md in 6d57cd86~'
      Expect bufname('') ==# '[git blame] t/fixture/example.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.1')
    end

    it 'is an error to blame older content on a non-blame line (though it is unlikely to occur)'
      edit t/fixture/example.md
      G blame

      setlocal modifiable
      1 put! ='foo'
      setlocal nomodifiable

      redir => log
      normal o
      redir END
      let log = log[1:]

      Expect log ==# 'g: Cannot find the commit id for the current line'
      Expect bufname('') ==# '[git blame] t/fixture/example.md'
      Expect getline(1, '$') ==# ['foo'] + readfile('t/fixture/blame.1')
    end

    it 'enables to undo/redo blamed content'
      edit t/fixture/example.md
      G blame

      normal! 15G$
      normal o
      call s:break_undo()
      Expect bufname('') ==# '[git blame] 523d0005~ t/fixture/example.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.2')

      normal! 12G$
      normal o
      call s:break_undo()
      Expect bufname('') ==# '[git blame] 577278fb~ t/fixture/sample.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.3')

      normal u
      Expect bufname('') ==# '[git blame] 523d0005~ t/fixture/example.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.2')

      normal u
      Expect bufname('') ==# '[git blame] t/fixture/example.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.1')

      " Because there is nothing to undo.
      normal u
      Expect bufname('') ==# '[git blame] t/fixture/example.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.1')

      execute 'normal' "\<C-r>"
      Expect bufname('') ==# '[git blame] 523d0005~ t/fixture/example.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.2')

      execute 'normal' "\<C-r>"
      Expect bufname('') ==# '[git blame] 577278fb~ t/fixture/sample.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.3')

      " Because there is nothing to redo.
      execute 'normal' "\<C-r>"
      Expect bufname('') ==# '[git blame] 577278fb~ t/fixture/sample.md'
      Expect getline(1, '$') ==# readfile('t/fixture/blame.3')
    end

    it 'keeps the cursor line at the logically same one - -1/+1'
      edit t/fixture/logical.md
      normal! 6G$
      G blame
      Expect bufname('') ==# '[git blame] t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.0')
      Expect [1, line('.')] == [1, 6]

      normal o
      Expect bufname('') ==# '[git blame] 2c258930~ t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.1')
      Expect [2, line('.')] == [2, 6]

      normal u
      Expect bufname('') ==# '[git blame] t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.0')
      Expect [3, line('.')] == [3, 6]

      execute 'normal' "\<C-r>"
      Expect bufname('') ==# '[git blame] 2c258930~ t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.1')
      Expect [4, line('.')] == [4, 6]
    end

    it 'keeps the cursor line at the logically same one - -5/+3'
      edit t/fixture/logical.md
      normal! 15G$
      G blame
      Expect bufname('') ==# '[git blame] t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.0')
      Expect [1, line('.')] == [1, 15]

      normal o
      Expect bufname('') ==# '[git blame] 036cb302~ t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.2')
      Expect [2, line('.')] == [2, 15 + (5 - 3) / 2]

      normal u
      Expect bufname('') ==# '[git blame] t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.0')
      Expect [3, line('.')] == [3, 15]

      execute 'normal' "\<C-r>"
      Expect bufname('') ==# '[git blame] 036cb302~ t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.2')
      Expect [4, line('.')] == [4, 15 + (5 - 3) / 2]
    end

    it 'keeps the cursor line at the logically same one - -3/+5'
      edit t/fixture/logical.md
      normal! 25G$
      G blame
      Expect bufname('') ==# '[git blame] t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.0')
      Expect [1, line('.')] == [1, 25]

      normal o
      Expect bufname('') ==# '[git blame] ab75b21c~ t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.3')
      Expect [2, line('.')] == [2, 25 + (3 - 5) / 2]

      normal u
      Expect bufname('') ==# '[git blame] t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.0')
      Expect [3, line('.')] == [3, 25]

      execute 'normal' "\<C-r>"
      Expect bufname('') ==# '[git blame] ab75b21c~ t/fixture/logical.md'
      Expect getline(1, '$') ==# readfile('t/fixture/logical.md.blame.3')
      Expect [4, line('.')] == [4, 25 + (3 - 5) / 2]
    end
  end
end
