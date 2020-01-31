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
  config.active_job.queue_adapter = :sidekiq
end
