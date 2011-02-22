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
        @email.header_string("X-Mail-Count")
      end

      def archive_url
        hint = @mailing_list.driver_data
        hint % [ mail_number ] if hint.present?
      end
    end
  end
end

