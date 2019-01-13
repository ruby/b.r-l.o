module MailingListIntegrationMailer

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

    m.header[:to] = mailing_lists.map(&:address)
    m.header[:subject] = "[#{issue.project.name} #{issue.tracker.name}##{issue.id}] #{issue.subject}"
    m
  end

  def attachments_added(user, attachments)
    mailing_lists = attatchments.first.container.project.mail_routes_for_attachments(attachments)

    m = super(user, attachments)

    m.header[:to] = mailing_lists.map(&:address)
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
  class << self
    def deliver_issue_add(issue)
      unless issue.originates_from_mail?
        issue_add(issue.author, issue).deliver_later
      end
    end

    def deliver_issue_edit(journal)
      unless journal.originates_from_mail?
        issue_edit(journal.user, journal).deliver_later
      end
    end

    def deliver_attachments_added(attachments)
      attachments_added(attachments.first.author, attachments).deliver_later
    end
  end

  prepend MailingListIntegrationMailer
end
