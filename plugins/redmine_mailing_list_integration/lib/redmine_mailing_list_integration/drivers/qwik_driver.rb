module RedmineMailingListIntegration
  module Drivers
    class QwikDriver < QuickMLDriver
      include TypicalDriver

      def archive_url
        @email.body.scan(%r[^archive-> (http://\S*)]).last.try(:first)
      end
    end
  end
end

