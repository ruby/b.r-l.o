# https://devcenter.heroku.com/articles/rails-unicorn

max_workers ENV["WEB_CONCURRENCY"] || 3
timeout 15

before_fork {
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
}
after_fork {
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end
  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
}
