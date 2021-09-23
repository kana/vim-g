call vspec#hint({'sid': 'g#vc#_sid()'})

filetype on
syntax enable

runtime plugin/g.vim

function! GetNormalizedDiff()
  return map(getline(1, '$'), {_, s -> substitute(s, '\v<\x{7}>', 'XXXXXXX', 'g')})
endfunction

describe 'Private function'
  describe 's:make_command_buffer_name()'
    after
      windo bwipeout!
    end

    it 'makes a buffer name based on its arguments'
      Expect Call('s:make_command_buffer_name', 'diff', ['HEAD', '--', '.'])
      \ ==# 'git diff HEAD -- .'
    end

    it 'tries to make a unique name if there is already a command buffer with the same command'
      new `='git diff HEAD -- .'`

      Expect Call('s:make_command_buffer_name', 'diff', ['HEAD', '--', '.'])
      \ ==# 'git diff HEAD -- . (2)'

      new `='git diff HEAD -- . (2)'`

      Expect Call('s:make_command_buffer_name', 'diff', ['HEAD', '--', '.'])
      \ ==# 'git diff HEAD -- . (3)'
    end
  end

  describe 's:make_command_line()'
    it 'automtaically escapes arguments'
      Expect Call('s:make_command_line', 'add', ['normal.path', 'path with spaces', '%weird#path!'])
      \ ==# "'git' 'add' 'normal.path' 'path with spaces' '\\%weird\\#path\\!'"
    end
  end
end

describe 'Public function'
  before
    call delete('tmp/test', 'rf')
    call mkdir('tmp/test', 'p')
    cd tmp/test
    !git init && touch foo && git add foo && git commit -m 'Initial commit'
  end

  after
    cd -
    windo bwipeout
  end

  describe 'g#vc#add()'
    it 'runs git add'
      !echo '1' >>foo

      Expect trim(system('git diff --quiet; echo $?')) == '1'
      Expect trim(system('git diff --quiet --staged; echo $?')) == '0'

      Expect g#vc#add('foo') to_be_true

      Expect trim(system('git diff --quiet; echo $?')) == '0'
      Expect trim(system('git diff --quiet --staged; echo $?')) == '1'
    end
  end

  describe 'g#vc#diff()'
    context 'without changes'
      it 'effectively does nothing if there are no changes'
        redir => log
        silent let result = g#vc#diff('HEAD', '--', '.')
        redir END

        Expect result == v:false
        Expect tabpagenr('$') == 1
        Expect winnr('$') == 1

        Expect split(log, '\n') ==# [
        \   'There are no changes.',
        \ ]
      end
    end

    context 'with changes'
      before
        !echo 'staged' >>foo
        !git add foo
        !echo 'unstaged' >>foo
      end

      it 'opens a new buffer to review both staged and unstaged changes'
        redir => log
        silent let result = g#vc#diff('HEAD', '--', '.')
        redir END

        Expect result == v:true
        Expect tabpagenr('$') == 1
        Expect winnr('$') == 2

        Expect bufname('%') ==# 'git diff HEAD -- .'
        Expect &l:filetype ==# 'diff'

        " Note that :redir captures the following messages, but they are
        " actually suppressed.
        Expect split(log, '\n') ==# [
        \   '"git diff HEAD -- ."  --No lines in buffer--',
        \   '7 more lines',
        \ ]

        Expect GetNormalizedDiff() ==# [
        \   'diff --git a/foo b/foo',
        \   'index XXXXXXX..XXXXXXX 100644',
        \   '--- a/foo',
        \   '+++ b/foo',
        \   '@@ -0,0 +1,2 @@',
        \   '+staged',
        \   '+unstaged',
        \ ]
      end

      it 'opens a new buffer to review staged changes'
        redir => log
        silent let result = g#vc#diff('--staged', '--', '.')
        redir END

        Expect result == v:true
        Expect tabpagenr('$') == 1
        Expect winnr('$') == 2

        Expect bufname('%') ==# 'git diff --staged -- .'
        Expect &l:filetype ==# 'diff'

        " Note that :redir captures the following messages, but they are
        " actually suppressed.
        Expect split(log, '\n') ==# [
        \   '"git diff --staged -- ."  --No lines in buffer--',
        \   '6 more lines',
        \ ]

        Expect GetNormalizedDiff() ==# [
        \   'diff --git a/foo b/foo',
        \   'index XXXXXXX..XXXXXXX 100644',
        \   '--- a/foo',
        \   '+++ b/foo',
        \   '@@ -0,0 +1 @@',
        \   '+staged',
        \ ]
      end

      it 'opens a new buffer to review unstaged changes'
        redir => log
        silent let result = g#vc#diff('--', '.')
        redir END

        Expect result == v:true
        Expect tabpagenr('$') == 1
        Expect winnr('$') == 2

        Expect bufname('%') ==# 'git diff -- .'
        Expect &l:filetype ==# 'diff'

        " Note that :redir captures the following messages, but they are
        " actually suppressed.
        Expect split(log, '\n') ==# [
        \   '"git diff -- ."  --No lines in buffer--',
        \   '7 more lines',
        \ ]

        Expect GetNormalizedDiff() ==# [
        \   'diff --git a/foo b/foo',
        \   'index XXXXXXX..XXXXXXX 100644',
        \   '--- a/foo',
        \   '+++ b/foo',
        \   '@@ -1 +1,2 @@',
        \   ' staged',
        \   '+unstaged',
        \ ]
      end
    end
  end

  describe 'g#vc#restore()'
    it 'runs git restore'
      !echo '1' >>foo

      Expect readfile('foo') == ['1']

      Expect g#vc#restore('foo') to_be_true

      Expect readfile('foo') == []
    end
  end
end
