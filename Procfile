release: bundle exec rake db:migrate redmine:plugins:migrate RAILS_ENV=production
web: bin/yjit bundle exec puma -C config/puma.rb
worker: RUBYOPT=--yjit bundle exec good_job start --max-threads=5
