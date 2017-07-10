release: bundle exec rake db:migrate RAILS_ENV=production
web: bundle exec rackup -s Rhebok --port $PORT -O ConfigFile=config/rhebok.rb
worker: bundle exec rake resque:work RAILS_ENV=production QUEUE=*
scheduler: bundle exec rake resque:scheduler RAILS_ENV=production
