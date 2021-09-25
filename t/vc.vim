call vspec#hint({'sid': 'g#vc#_sid()'})

filetype on
syntax enable

runtime plugin/g.vim

function! MaskCommitIds(lines)
  return a:lines->map({_, s -> substitute(s, '\v<\x{7}>', 'XXXXXXX', 'g')})
endfunction

describe 'Private function'
  describe 's:make_command_buffer_name()'
    after
       %bwipeout!
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
      Expect Call('s:make_command_line', ['add', 'normal.path', 'path with spaces', '%weird#path!'])
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
    %bwipeout
  end

  describe 'g#vc#add()'
    it 'runs git add'
      !echo '1' >>foo

      Expect trim(system('git diff --quiet; echo $?')) == '1'
      Expect trim(system('git diff --quiet --staged; echo $?')) == '0'

      redir => log
      silent let result = g#vc#add('foo')
      redir END

      Expect result to_be_true
      Expect split(log, '\n') ==# [
      \   'git add foo',
      \ ]

      Expect trim(system('git diff --quiet; echo $?')) == '0'
      Expect trim(system('git diff --quiet --staged; echo $?')) == '1'
    end

    it 'shows a message in case of error'
      redir => log
      silent let result = g#vc#add('no-such-file')
      redir END

      Expect result to_be_false
      Expect split(log, '\n') ==# [
      \   'git add no-such-file',
      \   'fatal: pathspec ''no-such-file'' did not match any files',
      \ ]

      Expect trim(system('git diff --quiet HEAD; echo $?')) == '0'
    end
  end

  describe 'g#vc#commit()'
    after
      silent! unlet g:g_vc_split_modifier
    end

    it 'effectively does nothing if there are no changes to commit'
      let bufnr = bufnr()

      redir => log
      silent let result = g#vc#commit('-a')
      redir END

      Expect result to_be_false
      Expect tabpagenr('$') == 1
      Expect winnr('$') == 1
      Expect bufnr() == bufnr

      Expect split(log, '\n') ==# [
      \   'There are no changes.',
      \ ]

      Expect systemlist('git log --oneline')->len() == 1
      Expect systemlist('git show --oneline')->MaskCommitIds() ==# [
      \   "XXXXXXX Initial commit",
      \   "diff --git a/foo b/foo",
      \   "new file mode 100644",
      \   "index XXXXXXX..XXXXXXX",
      \ ]
    end

    it 'opens a new buffer to edit commit message'
      """ Set up.

      !echo 'staged' >>foo
      !git add foo
      !echo 'unstaged' >>foo

      """ Open a new buffer.

      let bufnr = bufnr()

      redir => log
      silent let result = g#vc#commit('-v')
      redir END

      Expect result to_be_true
      Expect tabpagenr('$') == 1
      Expect winnr('$') == 2
      Expect bufnr() != bufnr
      Expect bufname('%') ==# 'git commit -v'
      Expect &l:filetype ==# 'gitcommit'

      " The following messages are actually suppressed.
      Expect split(log, '\n') ==# [
      \   '"git commit -v"  --No lines in buffer--',
      \   '20 more lines',
      \ ]

      Expect getline(1, '$')->MaskCommitIds() ==# [
      \   "",
      \   "# Please enter the commit message for your changes. Lines starting",
      \   "# with '#' will be ignored, and an empty message aborts the commit.",
      \   "#",
      \   "# On branch master",
      \   "# Changes to be committed:",
      \   "#\tmodified:   foo",
      \   "#",
      \   "# Changes not staged for commit:",
      \   "#\tmodified:   foo",
      \   "#",
      \   "# ------------------------ >8 ------------------------",
      \   "# Do not modify or remove the line above.",
      \   "# Everything below it will be ignored.",
      \   "diff --git a/foo b/foo",
      \   "index XXXXXXX..XXXXXXX 100644",
      \   "--- a/foo",
      \   "+++ b/foo",
      \   "@@ -0,0 +1 @@",
      \   "+staged"
      \ ]

      Expect systemlist('git log --oneline')->len() == 1
      Expect systemlist('git show --oneline')->MaskCommitIds() ==# [
      \   "XXXXXXX Initial commit",
      \   "diff --git a/foo b/foo",
      \   "new file mode 100644",
      \   "index XXXXXXX..XXXXXXX",
      \ ]

      """ This :write fails because of empty commit message.

      redir => log
      write
      redir END

      Expect tabpagenr('$') == 1
      Expect winnr('$') == 2

      " The "written" message is actually suppressed.
      Expect split(log, '\n') ==# [
      \   '".git/COMMIT_EDITMSG" 20L, 488B written',
      \   'Aborting commit due to empty commit message.',
      \ ]

      Expect systemlist('git log --oneline')->len() == 1
      Expect systemlist('git show --oneline')->MaskCommitIds() ==# [
      \   "XXXXXXX Initial commit",
      \   "diff --git a/foo b/foo",
      \   "new file mode 100644",
      \   "index XXXXXXX..XXXXXXX"
      \ ]

      " This :write succeeds and creates a new commit.

      redir => log
      0 put ='Some commit message'
      write
      redir END

      Expect tabpagenr('$') == 1
      Expect winnr('$') == 1
      Expect bufnr() == bufnr

      " The "written" message is actually suppressed.
      Expect split(log, '\n')->MaskCommitIds() ==# [
      \   "\".git/COMMIT_EDITMSG\" 21L, 508B written",
      \   " 1 file changed, 1 insertion(+)"
      \ ]

      Expect systemlist('git log --oneline')->len() == 2
      Expect systemlist('git show --oneline')->MaskCommitIds() ==# [
      \   "XXXXXXX Some commit message",
      \   "diff --git a/foo b/foo",
      \   "index XXXXXXX..XXXXXXX 100644",
      \   "--- a/foo",
      \   "+++ b/foo",
      \   "@@ -0,0 +1 @@",
      \   "+staged"
      \ ]
    end

    it 'warns and prevents an attempt of empty commit'
      !echo 'modified' >foo && git commit -am 'Modified' && rm foo && touch foo

      let bufnr = bufnr()

      redir => log
      silent let result = g#vc#commit('--amend', '-av')
      redir END

      Expect result to_be_false
      Expect tabpagenr('$') == 1
      Expect winnr('$') == 1
      Expect bufnr() == bufnr

      " Git might show a hint about empty commit like the following:
      "
      "     On branch master
      "     No changes
      "     You asked to amend the most recent commit, but doing so would make
      "     it empty. You can repeat your command with --allow-empty, or you can
      "     remove the commit entirely with "git reset HEAD^"."
      "
      " It would be better to display this message as is.  But this message is
      " not displayed if --dry-run is specified.  So that only the following
      " message is actually displayed at the moment.
      Expect split(log, '\n') ==# [
      \   'There are no changes.',
      \ ]

      " The last change is still not committed.
      Expect systemlist('git diff HEAD')->MaskCommitIds() ==# [
      \   "diff --git a/foo b/foo",
      \   "index XXXXXXX..XXXXXXX 100644",
      \   "--- a/foo",
      \   "+++ b/foo",
      \   "@@ -1 +0,0 @@",
      \   "-modified"
      \ ]
      Expect systemlist('git log --oneline')->len() == 2
      Expect systemlist('git show --oneline')->MaskCommitIds() ==# [
      \   "XXXXXXX Modified",
      \   "diff --git a/foo b/foo",
      \   "index XXXXXXX..XXXXXXX 100644",
      \   "--- a/foo",
      \   "+++ b/foo",
      \   "@@ -0,0 +1 @@",
      \   "+modified"
      \ ]
    end

    it 'opens a new window according to g:g_vc_split_modifier'
      !echo 'modified' >foo

      let bufnr = bufnr()
      let winid = win_getid()

      Expect winlayout() ==# ['leaf', winid]

      """ Open a new window with the default setting.

      silent let result = g#vc#commit('-a')

      Expect result to_be_true
      Expect tabpagenr('$') == 1
      Expect winnr('$') == 2
      Expect bufnr() != bufnr

      Expect bufwinid('') != winid
      Expect winlayout() ==# ['col', [['leaf', bufwinid('')], ['leaf', winid]]]

      """ Undo the layout.

      close

      Expect tabpagenr('$') == 1
      Expect winnr('$') == 1
      Expect bufnr() == bufnr

      Expect bufwinid('') == winid
      Expect winlayout() ==# ['leaf', winid]

      """ Open a new window with a tweaked setting.

      let g:g_vc_split_modifier = 'vertical'

      silent let result = g#vc#commit('-a')

      Expect result to_be_true
      Expect tabpagenr('$') == 1
      Expect winnr('$') == 2
      Expect bufnr() != bufnr

      Expect bufwinid('') != winid
      Expect winlayout() ==# ['row', [['leaf', bufwinid('')], ['leaf', winid]]]
    end
  end

  describe 'g#vc#diff()'
    context 'without changes'
      it 'effectively does nothing if there are no changes'
        let bufnr = bufnr()

        redir => log
        silent let result = g#vc#diff('HEAD', '--', '.')
        redir END

        Expect result == v:false
        Expect tabpagenr('$') == 1
        Expect winnr('$') == 1
        Expect bufnr() == bufnr

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

      after
        silent! unlet g:g_vc_split_modifier
      end

      it 'opens a new buffer to review both staged and unstaged changes'
        let bufnr = bufnr()

        redir => log
        silent let result = g#vc#diff('HEAD', '--', '.')
        redir END

        Expect result == v:true
        Expect tabpagenr('$') == 1
        Expect winnr('$') == 2
        Expect bufnr() != bufnr
        Expect bufname('%') ==# 'git diff HEAD -- .'
        Expect &l:filetype ==# 'diff'

        " Note that :redir captures the following messages, but they are
        " actually suppressed.
        Expect split(log, '\n') ==# [
        \   '"git diff HEAD -- ."  --No lines in buffer--',
        \   '7 more lines',
        \ ]

        Expect getline(1, '$')->MaskCommitIds() ==# [
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
        let bufnr = bufnr()

        redir => log
        silent let result = g#vc#diff('--staged', '--', '.')
        redir END

        Expect result == v:true
        Expect tabpagenr('$') == 1
        Expect winnr('$') == 2
        Expect bufnr() != bufnr
        Expect bufname('%') ==# 'git diff --staged -- .'
        Expect &l:filetype ==# 'diff'

        " Note that :redir captures the following messages, but they are
        " actually suppressed.
        Expect split(log, '\n') ==# [
        \   '"git diff --staged -- ."  --No lines in buffer--',
        \   '6 more lines',
        \ ]

        Expect getline(1, '$')->MaskCommitIds() ==# [
        \   'diff --git a/foo b/foo',
        \   'index XXXXXXX..XXXXXXX 100644',
        \   '--- a/foo',
        \   '+++ b/foo',
        \   '@@ -0,0 +1 @@',
        \   '+staged',
        \ ]
      end

      it 'opens a new buffer to review unstaged changes'
        let bufnr = bufnr()

        redir => log
        silent let result = g#vc#diff('--', '.')
        redir END

        Expect result == v:true
        Expect tabpagenr('$') == 1
        Expect winnr('$') == 2
        Expect bufnr() != bufnr
        Expect bufname('%') ==# 'git diff -- .'
        Expect &l:filetype ==# 'diff'

        " Note that :redir captures the following messages, but they are
        " actually suppressed.
        Expect split(log, '\n') ==# [
        \   '"git diff -- ."  --No lines in buffer--',
        \   '7 more lines',
        \ ]

        Expect getline(1, '$')->MaskCommitIds() ==# [
        \   'diff --git a/foo b/foo',
        \   'index XXXXXXX..XXXXXXX 100644',
        \   '--- a/foo',
        \   '+++ b/foo',
        \   '@@ -1 +1,2 @@',
        \   ' staged',
        \   '+unstaged',
        \ ]
      end

      it 'opens a new window according to g:g_vc_split_modifier'
        !echo 'modified' >foo

        let bufnr = bufnr()
        let winid = win_getid()

        Expect winlayout() ==# ['leaf', winid]

        """ Open a new window with the default setting.

        silent let result = g#vc#diff()

        Expect !!result to_be_true
        Expect tabpagenr('$') == 1
        Expect winnr('$') == 2
        Expect bufnr() != bufnr

        Expect bufwinid('') != winid
        Expect winlayout() ==# ['col', [['leaf', bufwinid('')], ['leaf', winid]]]

        """ Undo the layout.

        close

        Expect tabpagenr('$') == 1
        Expect winnr('$') == 1
        Expect bufnr() == bufnr

        Expect bufwinid('') == winid
        Expect winlayout() ==# ['leaf', winid]

        """ Open a new window with a tweaked setting.

        let g:g_vc_split_modifier = 'vertical'

        silent let result = g#vc#diff()

        Expect !!result to_be_true
        Expect tabpagenr('$') == 1
        Expect winnr('$') == 2
        Expect bufnr() != bufnr

        Expect bufwinid('') != winid
        Expect winlayout() ==# ['row', [['leaf', bufwinid('')], ['leaf', winid]]]
      end
    end
  end

  describe 'g#vc#restore()'
    it 'runs git restore'
      !echo '1' >>foo

      Expect readfile('foo') == ['1']

      redir => log
      silent let result = g#vc#restore('foo')
      redir END

      Expect result to_be_true
      Expect split(log, '\n') ==# [
      \   'git restore foo',
      \ ]

      Expect readfile('foo') == []
    end

    it 'shows a message in case of error'
      redir => log
      silent let result = g#vc#restore('no-such-file')
      redir END

      Expect result to_be_false
      Expect split(log, '\n') ==# [
      \   'git restore no-such-file',
      \   'error: pathspec ''no-such-file'' did not match any file(s) known to git',
      \ ]

      Expect trim(system('git diff --quiet HEAD; echo $?')) == '0'
    end
  end
end
