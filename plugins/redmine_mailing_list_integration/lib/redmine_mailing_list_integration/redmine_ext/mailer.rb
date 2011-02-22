Mailer.class_eval do
  class << self
    def deliver_issue_add(issue)
      unless issue.originates_from_mail?
        super(issue)
      end
    end
    def deliver_issue_edit(journal)
      unless journal.originates_from_mail?
        super(journal)
      end
    end

#    alias_method_chain :deliver_issue_add, :mailing_list_integration
#    alias_method_chain :deliver_issue_edit, :mailing_list_integration
  end

  def issue_add_with_mailing_list_integration(issue)
    issue_add_without_mailing_list_integration(issue)

    mailing_lists = issue.project.mail_routes_for_issue(issue)
    record_message(issue, nil, mailing_lists)

    self.cc += recipients
    self.recipients = mailing_lists.map(&:address)
  end

  def issue_edit_with_mailing_list_integration(journal)
    issue_edit_without_mailing_list_integration(journal)

    issue = journal.issue
    mailing_lists = issue.project.mail_routes_for_issue(issue)
    record_message(issue, journal, mailing_lists)

    self.cc += recipients
    self.recipients = mailing_lists.map(&:address)
  end
  alias_method_chain :issue_add, :mailing_list_integration
  alias_method_chain :issue_edit, :mailing_list_integration

  [
    [ 'document', 'added' ],
    [ 'news', 'added' ],
    [ 'message', 'posted' ],
    [ 'wiki_content', 'added', 'updated' ],
  ].each do |obj, *events|
    events.each do |event|
      define_method("#{obj}_#{event}_with_mailing_list_integration") do |*args|
        send "#{obj}_#{event}_without_mailing_list_integration", *args

        mailing_lists = args[0].project.send("mail_routes_for_#{obj}", args[0])
        send("record_message_on_issue_#{event}", args[0], mailing_lists) if obj == 'issue'

        self.cc += recipients
        self.recipients = mailing_lists.map(&:address)
      end
      alias_method_chain "#{obj}_#{event}", :mailing_list_integration
    end
  end

  def attachments_added_with_mailing_list_integration(attachments)
    attachments_added_without_mailing_list_integration(attachments)
    self.cc += recipients
    self.recipients = attatchments.first.container.project.mail_routes_for_attachments(attachments).map(&:address)
  end
  alias_method_chain :attachments_added, :mailing_list_integration

  private

  def record_message(issue, journal, mailing_lists)
    message_record_ids = mailing_lists.map {|ml|
      record = MailingListMessage.create! \
        :mailing_list => ml,
        :issue => issue,
        :journal => journal
      record.id
    }
    headers['X-Redmine-MailingListIntegration-Message-Ids'] = message_record_ids.join(",")
  end
end

