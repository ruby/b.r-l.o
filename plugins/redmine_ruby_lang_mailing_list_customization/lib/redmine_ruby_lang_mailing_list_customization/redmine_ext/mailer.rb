module RubyLangMailingListCustomizationMailer
  def issue_add(*args)
    m = super(*args)
    m.header[:from] = args[0].author.mail # args[0] == issue
    m
  end

  def issue_edit(*args)
    m = super(*args)
    m.header[:from] = args[0].user.mail # args[0] == journal
    m
  end

  def mail(headers)
    headers[:bcc] = headers[:cc]
    headers[:cc] = []
    locale = headers[:to].to_s.include?('ruby-dev') ? :ja : :en
    I18n.with_locale(locale) { super(headers) }
  end
end

Mailer.class_eval do
  prepend RubyLangMailingListCustomizationMailer
end
