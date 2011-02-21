require 'mailer'
Mailer.class_eval do
  def issue_add_with_ruby_lang_mailing_list_customization(issue)
    issue_add_without_ruby_lang_mailing_list_customization(issue)
    update_from(issue)
  end

  def issue_edit_with_ruby_lang_mailing_list_customization(issue)
    issue_edit_without_ruby_lang_mailing_list_customization(issue)
    update_from(issue)
  end

  alias_method_chain :issue_add, :ruby_lang_mailing_list_customization
  alias_method_chain :issue_edit, :ruby_lang_mailing_list_customization

  private
  def update_from(issue)
    if issue.author.anonymous? or issue.author.preference.try(:hide_mail?)
      from name_addr(issue.author.name, Setting.mail_from)
    else
      from name_addr(issue.author.name, issue.author.mail)
    end
  end

  def name_addr(name, addr_spec)
    addr = TMail::Address.parse(addr_spec)
    addr.name = name.to_s
    return addr.to_s
  end
end

