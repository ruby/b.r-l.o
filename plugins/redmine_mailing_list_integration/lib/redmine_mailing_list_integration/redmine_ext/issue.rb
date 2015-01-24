module RedmineMailingListIntegration
  module RedmineExt
    module IssueExt
      def self.included(klass)
        klass.class_eval do
          has_one :mailing_list_message, :conditions => 'journal_id IS NULL'
        end
      end
    end
  end
end
Issue.class_eval do
  include RedmineMailingListIntegration::RedmineExt::IssueExt
  include BasedOnMail
end
