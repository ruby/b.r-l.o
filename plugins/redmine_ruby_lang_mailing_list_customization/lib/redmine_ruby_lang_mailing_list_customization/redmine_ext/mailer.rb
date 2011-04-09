Mailer.class_eval do
  private
  def create_mail_with_ruby_lang_mailing_list_customization
    bcc = cc
    cc []
    create_mail_without_ruby_lang_mailing_list_customization
  end
  alias_method_chain :create_mail, :ruby_lang_mailing_list_customization
end

