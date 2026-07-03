# frozen_string_literal: true

# Datadog startup configuration lines are emitted by datadog/auto_instrument
# when the gem is loaded, before initializers run, so this must be set here
# rather than in config/initializers/datadog.rb.
ENV['DD_TRACE_STARTUP_LOGS'] ||= 'false'

# Defensively drop tags with an empty value from DD_TAGS before the gem
# parses it. libdatadog rejects tags that end with a colon.
if ENV['DD_TAGS']
  ENV['DD_TAGS'] = ENV['DD_TAGS'].split(/[\s,]+/).reject { |t| t.end_with?(':') }.join(',')
end

# The Datadog buildpack unconditionally re-exports DD_VERSION, so an unset
# value reaches the app as an empty string. The gem then builds a "version:"
# tag that libdatadog rejects with a WARN twice per boot. datadog/prerun.sh
# sets the real version in dynos, and this covers any environment where the
# variable is still empty.
ENV.delete('DD_VERSION') if ENV['DD_VERSION'] == ''

# The build environment and local development have no Datadog agent. DYNO is
# only set in Heroku runtime dynos, where the buildpack starts one. Tracing
# must be off from process start because spans created while Rails boots
# would already be flushed to 127.0.0.1:8126 before initializers could
# disable it.
ENV['DD_TRACE_ENABLED'] ||= 'false' unless ENV['DYNO']

# Rack 3.1.14 or later sets default limits of 4MB for query string bytesize
# and 4096 for the number of query parameters. These limits are too low
# for Redmine and can cause the following issues:
#
# - The low bytesize limit prevents the mail handler from processing incoming
#   emails larger than 4MB (https://www.redmine.org/issues/42962)
# - The low parameter limit prevents saving workflows with many statuses
#   (https://www.redmine.org/issues/42875)
#
# See also:
# - https://github.com/rack/rack/blob/v3.1.16/README.md#configuration
# - https://github.com/rack/rack/blob/v3.1.16/lib/rack/query_parser.rb#L54
# - https://github.com/rack/rack/blob/v3.1.16/lib/rack/query_parser.rb#L57
ENV['RACK_QUERY_PARSER_BYTESIZE_LIMIT'] ||= '33554432'
ENV['RACK_QUERY_PARSER_PARAMS_LIMIT'] ||= '65536'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
