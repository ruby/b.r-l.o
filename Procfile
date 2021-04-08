release: bundle exec rake db:migrate redmine:plugins:migrate RAILS_ENV=production
web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -C config/sidekiq.yml
