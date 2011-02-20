module RedmineMailingListIntegration
  module Drivers
    class QwikDriver < QuickMLDriver
      include TypicalDriver

      def archive_url
        @email.body.scan(%[^archive-> (http://.*)]).last
      end
    end
  end
end

