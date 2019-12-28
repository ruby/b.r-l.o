require 'based_on_mail'

module RedmineMailingListIntegration
  module RedmineExt
    module IssueExt
      extend ActiveSupport::Concern

      included do
        has_one :mailing_list_message, -> { where('journal_id IS NULL') }
      end
    end
  end
end
Issue.class_eval do
  include RedmineMailingListIntegration::RedmineExt::IssueExt
  include BasedOnMail
end
