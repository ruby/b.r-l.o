module RedmineMailingListIntegration
  module Drivers
    class MailmanDriver
      include TypicalDriver

      def likelihood
        if /\A\d/ =~ @email.header["X-Mailman-Version"].to_s && ml_name == @mailing_list.identifier
          EXACTLY_MATCHED
        else
          NOT_MATCHED
        end
      end

      def mail_number
        if @email.header["X-Mail-Count"].to_s
          # for mailman2
          @email.header["X-Mail-Count"].to_s
        else
          # for mailman3
          mail_count = @email.header["Subject"].match(/\[#{ml_name}:(\d+)\].*/)
          mail_count && mail_count[1]
        end
      end

      def ml_name
        if @email.header["X-ML-Name"].to_s
          # for mailman2
          @email.header["X-ML-Name"].to_s
        else
          # for mailman3
          list_id = @email.header["List-Id"].match(/\<(.*)\.ml\.ruby\-lang\.org\>/)
          list_id && list_id[1]
        end
      end

      def self.imap_query_for_mail_number(mailing_list, number)
        list_id = "<#{mailing_list.identifier}.ml.ruby-lang.org>"
        subject = "#{mailing_list.identifier}:#{number}"
        ['HEADER', "List-Id", list_id, 'HEADER', 'Subject', subject]
      end
    end
  end
end
