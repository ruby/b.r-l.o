module RedmineMailingListIntegration
  module Receptors
    class DumbReceptor
      def initialize(mailing_list)
      end

      Receptors::KNOWN_TYPES.each do |type|
        define_method("#{type}_receive?") do |obj|
          true
        end
      end
    end
  end
end
