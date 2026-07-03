require 'pg'
require 'datadog'

Datadog.configure do |c|
  c.profiling.enabled = true
  c.runtime_metrics.enabled = true
  c.version = ENV['HEROKU_RELEASE_VERSION']
  c.tracing.instrument :pg, comment_propagation: 'full'
  c.tracing.instrument :redis
end
