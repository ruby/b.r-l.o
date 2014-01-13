module RedmineMailingListIntegration
  module Drivers
    class QuickMLDriver
      include TypicalDriver

      def likelihood
        if @email.header["X-QuickML"].to_s == 'true' and
          @email.header["X-ML-Address"].to_s == @mailing_list.address then
          EXACTLY_MATCHED
        else
          NOT_MATCHED
        end
      end

      def self.imap_query_for_mail_number(mailing_list, number)
        ['HEADER', 'X-ML-Address', mailing_list.address, 'HEADER', 'X-Mail-Count', number.to_i]
      end
    end
  end
end

