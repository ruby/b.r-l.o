Mailer.class_eval do
  def issue_add_with_ruby_lang_mailing_list_customization(*args)
    issue_add_without_ruby_lang_mailing_list_customization(*args)
    update_from(args[0].author) # args[0] == issue
  end
  alias_method_chain :issue_add, :ruby_lang_mailing_list_customization

  def issue_edit_with_ruby_lang_mailing_list_customization(*args)
    issue_edit_without_ruby_lang_mailing_list_customization(*args)
    update_from(args[0].user) # args[0] == journal
  end
  alias_method_chain :issue_edit, :ruby_lang_mailing_list_customization

  private

  def mail_with_ruby_lang_mailing_list_customization
    headers[:bcc] = headers[:cc]
    headers[:cc] = []
    create_mail_without_ruby_lang_mailing_list_customization
  end
  alias_method_chain :mail, :ruby_lang_mailing_list_customization

  def update_from(user)
    if user.anonymous? or user.preference.try(:hide_mail?)
      from name_addr(user.name, Setting.mail_from)
    else
      from name_addr(user.name, user.mail)
    end
  end

  def name_addr(name, addr_spec)
    addr = TMail::Address.parse(addr_spec)
    addr.name = name.to_s
    return addr.to_s
  end
end
