require 'pg'
require 'datadog'

Datadog.configure do |c|
  c.version = ENV['HEROKU_RELEASE_VERSION']

  # Processes without an agent must not emit telemetry or the datadog gem
  # logs ECONNREFUSED. The build environment (assets:precompile and the
  # buildpack's "rails runner" config detection) never has an agent and is
  # recognizable by the absence of DYNO, which is also absent in local
  # development. Rake stays silent in runtime dynos too because release-phase
  # migration traces are not useful. Skipping the pg/redis instrumentation
  # keeps comment_propagation at the auto_instrument default, since 'full'
  # WARNs on every query while tracing is disabled.
  if ENV['DYNO'].nil? || File.basename($PROGRAM_NAME) == 'rake'
    c.tracing.enabled = false
    c.profiling.enabled = false
    c.runtime_metrics.enabled = false
  else
    c.profiling.enabled = true
    c.runtime_metrics.enabled = true
    c.tracing.instrument :pg, comment_propagation: 'full'
    c.tracing.instrument :redis
  end
end
