MailHandler.class_eval do
  private
  def receive_with_mailing_list_integration(email)
    if cycled?(email)
      @email = email
      receive_cycled
    else
      receive_without_mailing_list_integration(email)
    end
  end

  def dispatch_to_default_with_mailing_list_integration
    case
    when parent_message
      receive_issue_reply(parent_message.issue_id)
    when email.in_reply_to
      # TODO: should check it later
      # pending queue
    else
      dispatch_to_default_without_mailing_list_integration
    end
  end

  def receive_issue_with_mailing_list_integration
    issue = receive_issue_without_mailing_list_integration
    record_message(issue.id)
    issue
  end

  def receive_issue_reply_with_mailing_list_integration(issue_id)
    journal = receive_issue_reply_without_mailing_list_integration(issue_id)
    record_message(issue_id, journal.id)
    journal
  end

  def target_project_with_mailing_list_integration
    target_project_without_mailing_list_integration
  rescue MailHandler::MissingInformation
    if parent_message and parent_message.issue
      return parent_message.issue.project
    elsif issue_id = email.header_string("X-Redmine-Issue-Id")
      return Issue.find(issue_id).project
    else
      raise
    end
  end

  %w[
    receive
    dispatch_to_default receive_issue receive_issue_reply
    target_project
  ].each do |meth|
    alias_method_chain meth, :mailing_list_integration
  end

  private
  def cycled?(email)
    sender_email = email.from.to_a.first.to_s.strip
    email.header_string("X-Mailer") == "Redmine" and
      sender_email.downcase == Setting.mail_from.to_s.strip.downcase
  end

  def receive_cycled
    issue_id = email.header_string("X-Redmine-Issue-Id")
    ids = email.header_string("X-Redmine-MailingListIntegration-Message-Ids")
    if ids
      ids.split(',').each do |id|
        msg = MailingListMessage.find(id)
        if msg.mailing_list != driver.mailing_list or msg.issue_id.to_s != issue_id.to_s
          raise ArgumentError, "header mismatch"
        end
        msg.in_reply_to = email.in_reply_to.try(:join, ',')
        msg.references = email.references.try(:join, ',')
        msg.mail_number = driver.mail_number
        msg.archive_url = driver.archive_url
        msg.save!
      end
    end
  end

  def record_message(issue_id, journal_id = nil)
    MailingListMessage.create! :message_id => email.message_id,
      :in_reply_to => (email.in_reply_to && email.in_reply_to.join(",")),
      :references => (email.references && email.references.join(",")),
      :mailing_list => driver.mailing_list,
      :issue => (issue_id && Issue.find(issue_id)),
      :journal => (journal_id && Journal.find(journal_id)),
      :mail_number => driver.mail_number,
      :archive_url => driver.archive_url
  end

  def parent_message
    @parent_message ||= begin
      headers = [email.in_reply_to, email.references].flatten.compact.uniq
      headers.detect {|h|
        msg = MailingListMessage.find_by_message_id(h)
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
      raise MailHandler::MissingInformation, "Unable to determine driver" unless chosen
      chosen
    end
  end
end
