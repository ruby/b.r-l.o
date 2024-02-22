module RedmineMailingListIntegration
  module RedmineExt
    module Mailer
      def deliver_issue_add(issue)
        deliver_issue_add_to_mailing_lists(issue) unless issue.originates_from_mail?
        super
      end

      def deliver_issue_edit(journal)
        deliver_issue_edit_to_mailing_lists(journal) unless journal.originates_from_mail?
        super
      end

      def deliver_attachments_added(attachments)
        deliver_attachments_added_to_mailing_lists(attachments) if attachments.first.container_type == "Issue"
        super
      end

      private

      def deliver_issue_add_to_mailing_lists(issue)
        mailing_lists = issue.project.mail_routes_for_issue(issue)
        with(mailing_lists: mailing_lists).issue_add(issue.author, issue).deliver_later
      end

      def deliver_issue_edit_to_mailing_lists(journal)
        issue = journal.issue
        mailing_lists = issue.project.mail_routes_for_issue(issue)
        with(mailing_lists: mailing_lists).issue_edit(issue.author, journal).deliver_later
      end

      def deliver_attachments_added_to_mailing_lists(attachments)
        container = attachments.first.container
        mailing_lists = container.project.mail_routes_for_attachments(attachments)
        with(mailing_lists: mailing_lists).attachments_added(container.author, attachments).deliver_later
      end
    end
  end
end

Mailer.singleton_class.prepend RedmineMailingListIntegration::RedmineExt::Mailer

Mailer.after_action do
  if params && (mailing_lists = params[:mailing_lists])
    if @issue
      records = mailing_lists.map do |mailing_list|
        MailingListMessage.create!(mailing_list: mailing_list, issue: @issue, journal: @journal)
      end
      headers["X-Redmine-MailingListIntegration-Message-Ids"] = records.map(&:id).join(",")
    end
    headers[:to] = mailing_lists.map(&:address)
  end
end
