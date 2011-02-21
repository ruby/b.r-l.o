require 'issue'
module RedmineMailingListIntegration
  module RedmineExt
    module IssueExt
      def self.included(klass)
        klass.class_eval do
          has_one :mailing_list_message, :conditions => 'journal_id IS NULL'

          def originates_from_mail?
            if @originates_from_mail.nil?
              @originates_from_mail = true
            else
              @originates_from_mail
            end
          end
          attr_writer :originates_from_mail
        end
      end
    end
  end
end
class Issue
  include RedmineMailingListIntegration::RedmineExt::IssueExt
end
