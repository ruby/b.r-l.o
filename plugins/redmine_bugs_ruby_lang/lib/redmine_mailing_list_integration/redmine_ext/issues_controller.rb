module RedmineMailingListIntegration
  module RedmineExt
    module IssuesController
      def update_issue_from_params
        if val = super
          @issue.current_journal.originates_from_mail = false
        end
        val
      end
    end
  end
end

IssuesController.class_eval do
  prepend RedmineMailingListIntegration::RedmineExt::IssuesController
end
