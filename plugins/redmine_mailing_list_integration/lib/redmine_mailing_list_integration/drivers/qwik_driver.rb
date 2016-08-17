module RedmineMailingListIntegration
  module Drivers
    class QwikDriver < QuickMLDriver
      include TypicalDriver

      def archive_url
        @email.body.to_s.scan(%r[^archive-> (http://\S*)]).last&.first
      end
    end
  end
end
