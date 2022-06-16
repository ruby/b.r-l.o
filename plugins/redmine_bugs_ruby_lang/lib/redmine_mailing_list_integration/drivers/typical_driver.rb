module RedmineMailingListIntegration
  module Drivers
    module TypicalDriver
      def initialize(email, mailing_list)
        @email = email
        @mailing_list = mailing_list
      end
      attr_reader :mailing_list

      def likelihood
        raise NotImplementedError, "override #likelihood"
      end

      def self.included(klass)
        klass.module_eval do
          def self.imap_query_for_mail_number(number)
            raise NotImplementedError, "override TypicalDriver::imap_query_for_mail_number"
          end
        end
      end

      def mail_number
        @email.header["X-Mail-Count"].to_s
      end

      def archive_url
        self.class.archive_url_for(@mailing_list, mail_number)
      end

      module ClassMethods
        def archive_url_for(ml, number)
          hint = ml.driver_data
          hint % [ number ] if hint.present?
        end
      end

      def self.included(mod)
        mod.module_eval do
          extend ClassMethods
        end
      end
    end
  end
end
