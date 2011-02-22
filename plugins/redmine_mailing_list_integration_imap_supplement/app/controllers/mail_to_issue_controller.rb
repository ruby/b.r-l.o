require 'mail_to_issue'
class MailToIssueController < ApplicationController
  menu_item :mail_to_issue
  before_filter :authorize_global
  accept_key_auth :create

  def new
    @project = Project.find_by_identifier(params[:id])
    raise ActiveRecord::RecordNotFound unless @project
    @mail_to_issue = MailToIssue.new
  end

  def create
    @project = Project.find_by_identifier(params[:id])
    raise ActiveRecord::RecordNotFound unless @project
    @mail_to_issue = MailToIssue.new(params[:mail_to_issue])

    if @mail_to_issue.valid?
      ml = @mail_to_issue.mailing_list
      query = ml.driver_class.imap_query_for_mail_number(ml, @mail_to_issue.mail_number)
      msgs = RedmineMailingListIntegrationIMAPSupplement::IMAP.fetch(ml.identifier, query)

      number = "[#{ml.identifier}:#{@mail_to_issue.mail_number}]"
      if msgs.empty?
        @mail_to_issue.errors.add_to_base("no such mail #{number}")
        render :action => 'new'
      else
        msg = msgs.first.attr['RFC822']
        tracker = @mail_to_issue.tracker
        if issue = MailHandler.receive(msg, :issue => {:project => @project.identifier, :tracker => tracker.name}) and issue.kind_of?(Issue)
          redirect_to :controller => 'issues', :action => 'show', :id => issue.id
        else
          @mail_to_issue.errors.add_to_base("failed to process #{number}")
          render :action => 'new'
        end
      end
    else
      render :action => 'new'
    end
  end
end
