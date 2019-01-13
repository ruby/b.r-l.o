module MailingListIntegrationMailer
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

  def issue_add(user, issue)
    mailing_lists = issue.project.mail_routes_for_issue(issue)
    record_message(issue, nil, mailing_lists)

    m = super(user, issue)

    m.header[:to] = mailing_lists.map(&:address)
    m.header[:subject] = "[#{issue.project.name} #{issue.tracker.name}##{issue.id}] #{issue.subject}"
    m
  end

  def issue_edit(user, journal)
    issue = journal.issue
    mailing_lists = issue.project.mail_routes_for_issue(issue)
    record_message(issue, journal, mailing_lists)

    m = super(user, journal)

    s = "[#{issue.project.name} #{issue.tracker.name}##{issue.id}]"
    s << "[#{issue.status.name}]" if journal.new_value_for('status_id')
    s << " #{issue.subject}"

    m.header[:to] = mailing_lists.map(&:address)
    m.header[:subject] = s
    m
  end

  def attachments_added(attachments)
    m = super(attachments)

    mailing_lists = attatchments.first.container.project.mail_routes_for_attachments(attachments)
    m.header[:to] = mailing_lists.map(&:address)
    m.header[:subject] = "[#{container.project.name}] #{l(:label_attachment_new)}"
    m
  end

  private

  def record_message(issue, journal, mailing_lists)
    message_record_ids = mailing_lists.map {|ml|
      record = MailingListMessage.create!(
        mailing_list: ml,
        issue: issue,
        journal: journal
      )
      record.id
    }
    headers['X-Redmine-MailingListIntegration-Message-Ids'] = message_record_ids.join(",")
  end
end

Mailer.class_eval do
  prepend MailingListIntegrationMailer
end
