#!/usr/bin/env rake

task :ci => [:dump, :test]

task :dump do
  sh 'vim --version'
  sh 'git --version'
end

task :test do
  sh 'bundle exec vim-flavor test'
end
