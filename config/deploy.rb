set :application, 'redmine'
set :domain, 'fluorine.ruby-lang.org'
set :deploy_to, '/var/lib/redmine'
set :repository, 'git://github.com/yugui/redmine4ruby-lang.git'

set :revision, 'origin/ruby-lang.org/1.1'

shared_paths.merge!({
  'config/database.yml' => 'config/database.yml',
  'config/additional_environment.rb' => 'config/additional_environment.rb',
  'config/imap.yaml' => 'config/imap.yaml',
  'files' => 'files',
  'backup' => 'backup',
})
