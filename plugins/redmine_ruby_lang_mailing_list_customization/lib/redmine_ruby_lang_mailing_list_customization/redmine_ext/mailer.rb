Mailer.class_eval do
  def issue_add_with_ruby_lang_mailing_list_customization(*args)
    m = issue_add_without_ruby_lang_mailing_list_customization(*args)
    m.header[:from] = args[0].author.mail # args[0] == issue
    m
  end
  alias_method_chain :issue_add, :ruby_lang_mailing_list_customization

  def issue_edit_with_ruby_lang_mailing_list_customization(*args)
    m = issue_edit_without_ruby_lang_mailing_list_customization(*args)
    m.header[:from] = args[0].user.mail # args[0] == journal
    m
  end
  alias_method_chain :issue_edit, :ruby_lang_mailing_list_customization

  private

  def mail_with_ruby_lang_mailing_list_customization(headers)
    headers[:bcc] = headers[:cc]
    headers[:cc] = []
    locale = headers[:to].to_s.include?('ruby-dev') ? :ja : :en
    I18n.with_locale(locale) { mail_without_ruby_lang_mailing_list_customization(headers) }
  end
  alias_method_chain :mail, :ruby_lang_mailing_list_customization
end
