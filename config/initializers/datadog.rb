require 'pg'
require 'datadog'

# The version tag comes from DD_VERSION, set in datadog/prerun.sh. Setting it
# here would be too late for the crashtracker, which starts before
# initializers run.
Datadog.configure do |c|
  # Processes without an agent must not emit telemetry or the datadog gem
  # logs ECONNREFUSED. The build environment (assets:precompile and the
  # buildpack's "rails runner" config detection) never has an agent, and DYNO
  # cannot recognize it because Heroku sets DYNO in build dynos too. Instead
  # key off DD_HEROKU_DYNO, which the buildpack's .profile.d script exports
  # exactly where it starts an agent (never at build, never in local
  # development). Rake stays silent in runtime dynos too because release-phase
  # migration traces are not useful. Skipping the pg/redis instrumentation
  # keeps comment_propagation at the auto_instrument default, since 'full'
  # WARNs on every query while tracing is disabled.
  if ENV['DD_HEROKU_DYNO'].nil? || File.basename($PROGRAM_NAME) == 'rake'
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
