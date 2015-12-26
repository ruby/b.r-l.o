Airbrake.configure do |config|
  config.project_key = ENV['AIRBRAKE_API_KEY']
end if Rails.env.production?
