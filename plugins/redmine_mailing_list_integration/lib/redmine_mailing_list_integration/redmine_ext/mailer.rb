Mailer.class_eval do
  class << self
    def deliver_issue_add(issue)
      unless issue.originates_from_mail?
        to = issue.notified_users
        cc = issue.notified_watchers - to
        issue.each_notification(to + cc) do |users|
          Mailer.issue_add(issue, to & users, cc & users).deliver
        end
      end
    end

    def deliver_issue_edit(journal)
      unless journal.originates_from_mail?
        issue = journal.journalized.reload
        to = journal.notified_users
        cc = journal.notified_watchers
        journal.each_notification(to + cc) do |users|
          issue.each_notification(users) do |users2|
            Mailer.issue_edit(journal, to & users2, cc & users2).deliver
          end
        end
      end
    end
  end

  def issue_add_with_mailing_list_integration(issue, to_users, cc_users)
    mailing_lists = issue.project.mail_routes_for_issue(issue)
    record_message(issue, nil, mailing_lists)

    m = issue_add_without_mailing_list_integration(issue, to_users, cc_users)

    m.header[:to] = mailing_lists.map(&:address)
    m.header[:subject] = "[#{issue.project.name} #{issue.tracker.name}##{issue.id}] #{issue.subject}"
    m
  end
  alias_method_chain :issue_add, :mailing_list_integration

  def issue_edit_with_mailing_list_integration(journal, to_users, cc_users)
    issue = journal.issue
    mailing_lists = issue.project.mail_routes_for_issue(issue)
    record_message(issue, journal, mailing_lists)

    m = issue_edit_without_mailing_list_integration(journal, to_users, cc_users)

    s = "[#{issue.project.name} #{issue.tracker.name}##{issue.id}]"
    s << "[#{issue.status.name}]" if journal.new_value_for('status_id')
    s << " #{issue.subject}"

    m.header[:to] = mailing_lists.map(&:address)
    m.header[:subject] = s
    m
  end
  alias_method_chain :issue_edit, :mailing_list_integration

  def attachments_added_with_mailing_list_integration(attachments)
    m = attachments_added_without_mailing_list_integration(attachments)

    mailing_lists = attatchments.first.container.project.mail_routes_for_attachments(attachments)
    m.header[:to] = mailing_lists.map(&:address)
    m.header[:subject] = "[#{container.project.name}] #{l(:label_attachment_new)}"
    m
  end
  alias_method_chain :attachments_added, :mailing_list_integration

  private

  def record_message(issue, journal, mailing_lists)
    message_record_ids = mailing_lists.map {|ml|
      record = MailingListMessage.create!(
        :mailing_list => ml,
        :issue => issue,
        :journal => journal
      )
      record.id
    }
    headers['X-Redmine-MailingListIntegration-Message-Ids'] = message_record_ids.join(",")
  end
end
