module RedmineMailingListIntegration
  module Drivers
    class GoogleGroupsDriver
      include TypicalDriver

      def likelihood
        list_id = @email.header["List-ID"].match(/\<(.*)\.ruby\-lang\.org\>/)
        if list_id && list_id[1] == @mailing_list.identifier && @email.header["X-Google-Group-Id"]
          EXACTLY_MATCHED
        else
          NOT_MATCHED
        end
      end

      def self.imap_query_for_mail_number(mailing_list, id)
        # TODO: Can not find a way to search by Message-ID in Google Groups
        # ['HEADER', 'List-ID', "<#{mailing_list.identifier}.ruby-lang.org>", 'HEADER', '', id]
        []
      end
    end
  end
end
