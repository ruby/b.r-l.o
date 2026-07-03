require 'pg'
require 'datadog'

Datadog.configure do |c|
  c.version = ENV['HEROKU_RELEASE_VERSION']

  # Build-time rake tasks (assets:precompile, assets:clean) run without an
  # agent, so emitting traces only produces ECONNREFUSED errors in build logs.
  # Instrumenting pg with comment_propagation 'full' would also WARN on every
  # query once tracing is disabled, so rake keeps the auto_instrument defaults.
  if File.basename($PROGRAM_NAME) == 'rake'
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
