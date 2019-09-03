module MailingListIntegrationMailHandler
  def receive(email, options = {})
    if cycled?(email)
      @email = email
      receive_cycled
    else
      super(email, options)
    end
  end

  def dispatch_to_default
    case
    when parent_message
      receive_issue_reply(parent_message.issue_id)
    when email.in_reply_to
      dispatch_to_chiken_and_egg
    else
      super
    end
  end

  def receive_issue
    issue = super
    record_message(issue.id)
    issue
  end

  def receive_issue_reply(issue_id, from_journal=nil)
    journal = super(issue_id, from_journal)
    record_message(issue_id, journal.id)
    journal
  end

  def target_project
    super
  rescue MailHandler::MissingInformation
    if parent_message and parent_message.issue
      return parent_message.issue.project
    elsif issue_id = email.header["X-Redmine-Issue-Id"].to_s
      return Issue.find(issue_id).project
    else
      raise
    end
  end

  # override this method to do what you want for mails which has an unknown parent
  def dispatch_to_chiken_and_egg
    super
  end

  def cycled?(email)
    [email.header["X-Mailer"]].flatten.map(&:to_s).uniq.first == "Redmine" and
      [email.header["X-Redmine-Host"]].flatten.map(&:to_s).uniq.first == Setting.host_name
  end

  def receive_cycled
    issue_id = email.header["X-Redmine-Issue-Id"].to_s
    ids = email.header["X-Redmine-MailingListIntegration-Message-Ids"].to_s
    if ids
      ids.split(',').each do |id|
        if msg = MailingListMessage.where(id: id).first
          if msg.mailing_list != driver.mailing_list or msg.issue_id.to_s != issue_id
            raise ArgumentError, "header mismatch"
          end
          msg.in_reply_to = (email[:in_reply_to] && email[:in_reply_to].message_ids.join(','))
          msg.references = (email[:references] && email[:references].message_ids.join(','))
          msg.mail_number = driver.mail_number
          msg.archive_url = driver.archive_url
          msg.save!
        end
      end
    end
  end

  def record_message(issue_id, journal_id = nil)
    MailingListMessage.create! message_id: email.message_id,
      in_reply_to: (email[:in_reply_to] && email[:in_reply_to].message_ids.join(",")),
      references: (email[:references] && email[:references].message_ids.join(",")),
      mailing_list: driver.mailing_list,
      issue: (issue_id && Issue.find(issue_id)),
      journal: (journal_id && Journal.find(journal_id)),
      mail_number: driver.mail_number,
      archive_url: driver.archive_url
  end

  def parent_message
    @parent_message ||= begin
      headers = [email.in_reply_to, email.references].flatten.map(&:to_s).compact.uniq
      headers.detect {|h|
        msg = MailingListMessage.find_by(message_id: h)
        break msg if msg
      }
    end
  end

  def driver
    @driver ||= begin
      chosen = MailingList.all.map{|ml|
        ml.driver_for(email)
      }.reject{|c|
        c.likelihood <= RedmineMailingListIntegration::Drivers::NOT_MATCHED
      }.sort_by(&:likelihood).last
      raise MailHandler::MissingInformation, "Unable to determine driver #{email.subject rescue nil}" unless chosen
      chosen
    end
  end
end

MailHandler.class_eval do
  prepend MailingListIntegrationMailHandler
end
