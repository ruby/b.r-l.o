module RedmineMailingListIntegration
  module RedmineExt
    module Issue
      extend ActiveSupport::Concern

      included do
        has_one :mailing_list_message, -> { where('journal_id IS NULL') }
      end
    end
  end
end
Issue.class_eval do
  include RedmineMailingListIntegration::RedmineExt::Issue
  include BasedOnMail
end
