Dir[File.dirname(__FILE__) + "/core_ext/*.rb"].each { |file| require(file) }

module ActiveSupport
  class HashWithIndifferentAccess < Hash
    def select(*args, &block)
      dup.tap { |hash| hash.select!(*args, &block) }
    end

    def reject(*args, &block)
      dup.tap { |hash| hash.reject!(*args, &block) }
    end
  end

  class OrderedHash < ::Hash
    def select(*args, &block)
      dup.tap { |hash| hash.select!(*args, &block) }
    end

    def reject(*args, &block)
      dup.tap { |hash| hash.reject!(*args, &block) }
    end
  end
end
