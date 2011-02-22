IssuesController.class_eval do
  private
  def update_issue_from_params_with_mailing_list_integration
    update_issue_from_params_without_mailing_list_integration
    @issue.current_journal.originates_from_mail = false
  end

  alias_method_chain :update_issue_from_params, :mailing_list_integration
end
