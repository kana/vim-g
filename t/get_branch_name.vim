call vspec#hint({'scope': 'g#_scope()'})

describe 'g#get_branch_name'
  before
    ResetContext
    call delete('tmp/test', 'rf')
    call mkdir('tmp/test', 'p')
    cd tmp/test
  end

  after
    cd -
  end

  it 'returns "-" for non-Git directory'
    Expect g#get_branch_name('.') ==# '-'
  end

  it 'returns the current branch'
    !git init && touch foo && git add foo && git commit -m 'Initial commit'
    Expect g#get_branch_name('.') ==# 'master'
  end

  it 'returns a hint of the currently detached HEAD'
    !git init && touch foo && git add foo && git commit -m 'Initial commit'
    !git checkout master~0
    Expect g#get_branch_name('.') ==# 'master~0'
  end

  it 'returns a cached result'
    !git init && touch foo && git add foo && git commit -m 'Initial commit'
    Expect g#get_branch_name('.') ==# 'master'

    !git checkout master~0
    Expect g#get_branch_name('.') ==# 'master'

    !git checkout master
    Expect g#get_branch_name('.') ==# 'master'

    sleep 1
    !git checkout master~0
    Expect g#get_branch_name('.') ==# 'master~0'
  end

  " TODO: Add more test cases
end
