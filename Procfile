release: bundle exec rake db:migrate redmine:plugins:migrate RAILS_ENV=production
web: bundle exec puma -C config/puma.rb
worker: RUBYOPT=--jit bundle exec good_job start --max-threads=5
