runtime plugin/g.vim

describe ':G args'
  after
    %argdelete
  end

  it 'warns if no pattern is given'
    redir => log
    G args
    redir END
    let log = log[1:]

    Expect log ==# 'g: Specify at least one pattern.'
    Expect argv() ==# []
  end

  it 'warns given patterns do not match anything'
    redir => log
    G args 't*args'
    redir END
    let log = log[1:]

    Expect log ==# 'g: Nothing matched.'
    Expect argv() ==# []
  end

  it 'lists files based on patterns'
    G args t*args t*branch
    Expect argv() ==# [
    \   'autoload/g/args.vim',
    \   'autoload/g/branch.vim',
    \   't/args.vim',
    \   't/branch.vim',
    \ ]
  end

  it 'uses patterns as is if they are quoted'
    G args 't*args.vim'
    Expect argv() ==# ['t/args.vim']
  end
end
