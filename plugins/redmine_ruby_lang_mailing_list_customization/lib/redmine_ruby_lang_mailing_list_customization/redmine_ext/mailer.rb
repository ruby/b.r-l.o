Mailer.class_eval do
  private

  def mail_with_ruby_lang_mailing_list_customization(headers)
    headers[:bcc] = headers[:cc]
    headers[:cc] = []
    mail_without_ruby_lang_mailing_list_customization(headers)
  end
  alias_method_chain :mail, :ruby_lang_mailing_list_customization
end
