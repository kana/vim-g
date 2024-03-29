call vspec#hint({'scope': 'g#branch#_scope()', 'sid': 'g#branch#_sid()'})

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
      !git init -b master && touch foo && git add foo && git commit -m 'Initial commit'
    end

    it 'returns the current branch'
      Expect g#branch#get_name('.') ==# 'master'
    end

    it 'returns a hint of the currently detached HEAD'
      !git checkout master~0
      Expect g#branch#get_name('.') ==# 'master~0'
    end

    it 'returns a cached result'
      Expect Ref('s:branch_name_cache') ==# {}

      let valid_cache_key = Call('s:branch_name_cache_key', '.')
      call Set('s:branch_name_cache', {'.': ['cached value', valid_cache_key]})
      Expect g#branch#get_name('.') ==# 'cached value'

      " Invalidate the cache key which is based on getftime().
      sleep 1

      !git checkout master~0
      Expect g#branch#get_name('.') ==# 'master~0'
    end

    " TODO: Add more test cases
  end
end
