call vspec#hint({'sid': 'g#vc#_sid()'})

filetype on
syntax enable

runtime plugin/g.vim

describe 's:make_command_line()'
  it 'automtaically escapes arguments'
    Expect Call('s:make_command_line', 'add', ['normal.path', 'path with spaces', '%weird#path!'])
    \ ==# "'git' 'add' 'normal.path' 'path with spaces' '\\%weird\\#path\\!'"
  end
end

describe 'Function'
  before
    call delete('tmp/test', 'rf')
    call mkdir('tmp/test', 'p')
    cd tmp/test
    !git init && touch foo && git add foo && git commit -m 'Initial commit'
  end

  after
    cd -
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

  describe 'g#vc#restore()'
    it 'runs git restore'
      !echo '1' >>foo

      Expect readfile('foo') == ['1']

      Expect g#vc#restore('foo') to_be_true

      Expect readfile('foo') == []
    end
  end
end
