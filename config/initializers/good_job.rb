# config/initializers/good_job.rb
GoodJob::Engine.middleware.use(Rack::Auth::Basic) do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(ENV["IMAP_USERNAME"], username) &&
    ActiveSupport::SecurityUtils.secure_compare(ENV["IMAP_PASSWORD"], password)
end
