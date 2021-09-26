       %bwipeout!
    %bwipeout
    after
      silent! unlet g:g_vc_split_modifier
    end

      let bufnr = bufnr()

      Expect bufnr() == bufnr

      Expect systemlist('git log --oneline')->len() == 1
      Expect systemlist('git show --oneline')->MaskCommitIds() ==# [
      \   "XXXXXXX Initial commit",
      \   "diff --git a/foo b/foo",
      \   "new file mode 100644",
      \   "index XXXXXXX..XXXXXXX",
      \ ]
      let bufnr = bufnr()

      Expect bufnr() != bufnr
      " The "written" message is actually suppressed.
      Expect bufnr() == bufnr
      " The "written" message is actually suppressed.
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
        let bufnr = bufnr()

        Expect bufnr() == bufnr
      after
        silent! unlet g:g_vc_split_modifier
      end

        let bufnr = bufnr()

        Expect bufnr() != bufnr
        let bufnr = bufnr()

        Expect bufnr() != bufnr
        let bufnr = bufnr()

        Expect bufnr() != bufnr

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