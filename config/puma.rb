workers 2
threads_count = 5
threads threads_count, threads_count

# Update git repository on heroku dyno restart
# https://github.com/ruby/heroku-buildpack-bugs-ruby-lang/blob/master/bin/compile
fork{ system "git -C /app/repos/git/ruby fetch origin refs/heads/*:refs/heads/*" rescue nil }

preload_app!

port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

on_worker_boot do
  # Worker specific setup for Rails 4.1+
  # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
  ActiveRecord::Base.establish_connection
end
