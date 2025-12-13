require 'pg'
require 'datadog'

Datadog.configure do |c|
  c.tracing.instrument :pg
end
