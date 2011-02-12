Mailer.class_eval do
  [
    [ 'issue', 'add', 'edit' ],
    [ 'document', 'added' ],
    [ 'news', 'added' ],
    [ 'message', 'posted' ],
    [ 'wiki_content', 'added', 'updated' ],
  ].each do |obj, *events|
    events.each do |event|
      define_method("#{obj}_#{event}_with_mailing_list_integration") do |*args|
        send "#{obj}_#{event}_without_mailing_list_integration", *args

        self.cc += recipients
        self.recipients = args[0].project.send("mail_routes_for_#{obj}", args[0])
      end
      alias_method_chain "#{obj}_#{event}", :mailing_list_integration
    end
  end

  def attachments_added_with_mailing_list_integration(attachments)
    attachments_added_without_mailing_list_integration(attachments)
    self.cc += recipients
    self.recipients = attatchments.first.container.project.mail_routes_for_attachments(attachments)
  end
  alias_method_chain :attachments_added, :mailing_list_integration
end

