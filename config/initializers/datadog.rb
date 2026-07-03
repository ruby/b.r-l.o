require 'pg'
require 'datadog'

Datadog.configure do |c|
  c.profiling.enabled = true
  c.runtime_metrics.enabled = true
  c.env = 'prod'
  c.service = 'bugs-ruby-lang'
  c.version = ENV['HEROKU_RELEASE_VERSION']
  c.tracing.contrib.global_default_service_name.enabled = true
  c.tracing.instrument :pg, comment_propagation: 'full'
  c.tracing.instrument :redis

  # Build-time rake tasks (assets:precompile, assets:clean) run without an
  # agent, so emitting traces only produces ECONNREFUSED errors in build logs.
  if File.basename($PROGRAM_NAME) == 'rake'
    c.tracing.enabled = false
    c.profiling.enabled = false
    c.runtime_metrics.enabled = false
  end
end
