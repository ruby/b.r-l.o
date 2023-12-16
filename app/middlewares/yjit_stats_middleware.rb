class YjitStatsMiddleware
  YJIT_STATS_REQUEST_INTERVAL = 10
  CUSTOM_METRICS = [
    :code_region_size,
    :yjit_alloc_size,
    :live_iseq_count,
    :cold_iseq_entry,
    :compiled_iseq_entry,
    :compiled_iseq_count,
    :compiled_blockid_count,
    :compiled_block_count,
    :compiled_branch_count,
  ]

  def initialize(app, logger: Rails.logger)
    @app = app
    @count = 0
    @logger = logger
  end

  def call(env)
    @count += 1
    with_yjit_stats do
      @app.call(env)
    end
  end

  private

  def with_yjit_stats
    request_start_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
    yield
  ensure
    begin
      if request_start_ms
        request_time_ms = Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond) - request_start_ms
        NewRelic::Agent.record_metric('Custom/Unicorn/request_time_ms', request_time_ms)
      end
      NewRelic::Agent.record_metric('Custom/Unicorn/request_count', @count)

      if using_yjit? && (@count % YJIT_STATS_REQUEST_INTERVAL) == 0
        stats = RubyVM::YJIT.runtime_stats
        CUSTOM_METRICS.each do |metric|
          NewRelic::Agent.record_metric("Custom/YJIT/#{metric}", stats[metric])
        end
      end
    rescue => e
      @logger.error(e.full_message)
    end
  end

  def using_yjit?
    defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
  end
end
