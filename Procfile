release: bundle exec rake db:migrate redmine:plugins:migrate RAILS_ENV=production
web: RUBYOPT=--jit bundle exec puma -C config/puma.rb
worker: RUBYOPT=--jit bundle exec sidekiq -C config/sidekiq.yml
