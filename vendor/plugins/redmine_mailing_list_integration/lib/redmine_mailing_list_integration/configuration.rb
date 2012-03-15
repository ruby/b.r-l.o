require 'redmine_mailing_list_integration/drivers'
require 'redmine_mailing_list_integration/receptors'
module RedmineMailingListIntegration
  module Configuration
    class << (MAILING_LIST_CONFIGURATOR = Object.new)
      def driver(name, klass)
        RedmineMailingListIntegration::Drivers.register(name, klass)
      end

      def receptor(name, klass)
        RedmineMailingListIntegration::Receptors.register(name, klass)
      end
    end
    def mailing_list_integration(&block)
      MAILING_LIST_CONFIGURATOR.instance_eval(&block)
    end
  end
end
