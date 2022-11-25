module RedmineMailingListIntegration
  module Drivers
    class MailmanDriver
      include TypicalDriver

      def likelihood
        Rails.logger.info "ml_name: #{ml_name}"
        if /\A\d/ =~ @email.header["X-Mailman-Version"].to_s && ml_name == @mailing_list.identifier
          EXACTLY_MATCHED
        else
          NOT_MATCHED
        end
      end

      def mail_number
        mail_count = @email.header["Subject"].to_s.match(/\[#{ml_name}:(\d+)\].*/)
        Rails.logger.info "mail_count: #{mail_count}"
        mail_count && mail_count[1]
      end

      def ml_name
        list_id = @email.header["List-Id"].to_s.match(/\<(.*)\.ml\.ruby\-lang\.org\>/)
        Rails.logger.info "list_id: #{list_id}"
        ml_name = list_id && list_id[1]
      end

      def self.imap_query_for_mail_number(mailing_list, number)
        list_id = "<#{mailing_list.identifier}.ml.ruby-lang.org>"
        subject = "#{mailing_list.identifier}:#{number}"
        ['HEADER', "List-Id", list_id, 'HEADER', 'Subject', subject]
      end
    end
  end
end
