class YJITStatsMiddleware
  CUSTOM_METRICS = [
    :code_region_size,
    :yjit_alloc_size,
  ]

  def initialize(app)
    @app = app
  end

  def call(env)
    if defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
      record_yjit_stats
    end
    @app.call(env)
  end

  private

  def record_yjit_stats
    stats = RubyVM::YJIT.runtime_stats
    CUSTOM_METRICS.each do |metric|
      NewRelic::Agent.record_metric("Custom/YJIT/#{metric}", stats[metric])
    end
  end
end
