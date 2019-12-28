module RedmineMailingListIntegration
  module Drivers
    class FmlDriver
      include TypicalDriver

      def likelihood
        if /\Afml / =~ @email.header["List-Software"].to_s and
          @email.header["X-ML-Name"].to_s == @mailing_list.identifier then
          EXACTLY_MATCHED
        else
          NOT_MATCHED
        end
      end

      def self.imap_query_for_mail_number(mailing_list, number)
        ['HEADER', 'X-ML-Name', mailing_list.identifier, 'HEADER', 'X-Mail-Count', number.to_i]
      end
    end
  end
end
