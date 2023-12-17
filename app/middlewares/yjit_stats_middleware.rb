# frozen_string_literal: true
class YjitStatsMiddleware
  STAGING = ENV['NEW_RELIC_APP_NAME'] == 'staging-bugs-ruby-lang'
  YJIT_STATS_REQUEST_INTERVAL = STAGING ? 1 : 10
  YJIT_STATS_STRING_REQUEST_INTERVAL = STAGING ? 10 : 1000

  CUSTOM_METRICS = [
    # Always available
    :code_region_size,
    :yjit_alloc_size,
    :live_iseq_count,
    :compiled_iseq_entry,
    :compiled_iseq_count,
    :compiled_blockid_count,
    :compiled_block_count,
    :compiled_branch_count,
    :cold_iseq_entry,

    # --yjit-stats only
    :ratio_in_yjit,
  ]

  def initialize(app, logger: Rails.logger)
    @app = app
    @count = 0
    @logger = logger
  end

  def call(env)
    @count += 1
    with_yjit_stats(@count) do
      @app.call(env)
    end
  end

  private

  def with_yjit_stats(count)
    request_start_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
    yield
  ensure
    begin
      # Emit time spent for every request
      group = using_yjit? ? 'yjit' : 'interp'
      if request_start_ms
        request_time_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - request_start_ms
        NewRelic::Agent.record_metric("Custom/Request/time_ms/#{group}", request_time_ms)
      end

      # Emit more stats for sampled requests
      if (count % YJIT_STATS_REQUEST_INTERVAL) == 0
        NewRelic::Agent.record_metric("Custom/Request/count/#{group}", count)
        if ENV.key?('DYNO')
          NewRelic::Agent.record_metric('Custom/Heroku/dyno', ENV['DYNO'].to_i)
        end

        if using_yjit?
          stats = RubyVM::YJIT.runtime_stats
          CUSTOM_METRICS.each do |metric|
            NewRelic::Agent.record_metric("Custom/YJIT/#{metric}", stats[metric]) if stats.key?(metric)
          end
        end
      end

      # Log YJIT stats string once in a while
      if yjit_stats? && (count % YJIT_STATS_STRING_REQUEST_INTERVAL) == 0
        @logger.info("[request_count: #{count}] #{RubyVM::YJIT.stats_string}")
      end
    rescue => e
      @logger.error(e.full_message)
    end
  end

  def using_yjit?
    defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
  end

  def yjit_stats?
    using_yjit? && RubyVM::YJIT.stats_enabled?
  end
end
