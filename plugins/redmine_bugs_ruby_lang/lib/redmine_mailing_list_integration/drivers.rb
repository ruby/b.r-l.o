module RedmineMailingListIntegration
  module Drivers
    EXACTLY_MATCHED = 100.0
    NOT_MATCHED = 0.0

    @map = {}
    def self.register(name, klass)
      name = name.to_s.dup
      if @map.key?(name)
        raise ArgumentError, "mailing list driver name #{name.inspect} has already been taken"
      else
        @map[name] = klass
      end
    end

    def self.registered_drivers
      @map.values
    end

    def self.registered_driver_names
      @map.keys
    end

    def self.driver_for(name)
      @map[name] or raise ArgumentError, "Unrecognized driver name #{name.inspect}"
    end
  end
end
