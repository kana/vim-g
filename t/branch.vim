call vspec#hint({'scope': 'g#branch#_scope()'})

describe 'g#branch#get_name'
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
    Expect g#branch#get_name('.') ==# '-'
  end

  describe 'in a Git repository'
    before
      !git init && touch foo && git add foo && git commit -m 'Initial commit'
    end

    it 'returns the current branch'
      Expect g#branch#get_name('.') ==# 'master'
    end

    it 'returns a hint of the currently detached HEAD'
      !git checkout master~0
      Expect g#branch#get_name('.') ==# 'master~0'
    end

    it 'returns a cached result'
      Expect g#branch#get_name('.') ==# 'master'

      !git checkout master~0
      Expect g#branch#get_name('.') ==# 'master'

      !git checkout master
      Expect g#branch#get_name('.') ==# 'master'

      sleep 1
      !git checkout master~0
      Expect g#branch#get_name('.') ==# 'master~0'
    end

    " TODO: Add more test cases
  end
end
