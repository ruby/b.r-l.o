# Copy this file to additional_environment.rb and add any statements
# that need to be passed to the Rails::Initializer.  `config` is
# available in this context.
#
# Example:
#
#   config.log_level = :debug
#   ...
#

if Rails.env.production?
  config.log_level = :info
  config.force_ssl = true
  config.cache_store = :redis_store, ENV['REDIS_URL'], { expires_in: 24.hours }
end
