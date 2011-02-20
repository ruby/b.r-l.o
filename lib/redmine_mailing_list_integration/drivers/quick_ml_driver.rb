module RedmineMailingListIntegration
  module Drivers
    class QuickMLDriver
      include TypicalDriver

      def likelihood
        if @email.header_string("X-QuickML") == 'true' and
          @email.header_string("X-ML-Address") == @mailing_list.address then
          EXACTLY_MATCHED
        else
          NOT_MATCHED
        end
      end
    end
  end
end

