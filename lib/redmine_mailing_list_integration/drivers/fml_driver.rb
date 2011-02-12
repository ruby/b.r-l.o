module RedmineMailingListIntegration
  module Drivers
    class FmlDriver
      def initialize(email, mailing_list)
        @email = email
        @mailing_list = mailing_list
      end

      attr_reader :mailing_list

      def likelihood
        if /\Afml / =~ @email.header_string("List-Software") and
          @email.header_string("X-ML-Name") == @mailing_list.identifier then
          EXACTLY_MATCHED
        else
          NOT_MATCHED
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
