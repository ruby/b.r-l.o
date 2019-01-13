module RubyLangMailingListCustomizationMailer
  def issue_add(user, issue)
    m = super(user, issue)

    m.header[:from] = issue.author.mail
    m
  end

  def issue_edit(user, journal)
    m = super(*args)

    m.header[:from] = journal.user.mail
    m
  end

  def mail(headers={}, &block)
    headers[:bcc] = (headers[:bcc] || []).concat(headers[:cc])
    headers[:cc] = []
    locale = headers[:to].to_s.include?('ruby-dev') ? :ja : :en
    I18n.with_locale(locale) { super(headers) }
  end
end

Mailer.class_eval do
  prepend RubyLangMailingListCustomizationMailer
end
