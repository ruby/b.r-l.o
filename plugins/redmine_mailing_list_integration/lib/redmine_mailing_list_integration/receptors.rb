module RedmineMailingListIntegration
  module Receptors
    KNOWN_TYPES = %w[
      issue document news message attatchments wiki_content
    ].freeze

    @map = {}
    def self.register(name, klass)
      name = name.to_s.dup
      if @map.key?(name)
        raise ArgumentError, "mailing list receptor name #{name.inspect} has already been taken"
      else
        @map[name] = klass
      end
    end

    def self.registered_receptors
      @map.values
    end

    def self.registered_receptor_names
      @map.keys
    end

    def self.receptor_for(name)
      @map[name] or raise ArgumentError, "Unrecognized receptor name #{name.inspect}"
    end
  end
end
