require 'redmine_ruby_lang_mailing_list_customization/redmine_ext/application_helper'

Attachment.class_eval do
  def text?
    !!(self.filename =~ /\.(txt|rb|log|patch|diff)$/i)
  end
end

require 'redmine_ruby_lang_mailing_list_customization/redmine_ext/mail_handler'
require 'redmine_ruby_lang_mailing_list_customization/redmine_ext/mailer'
require 'redmine_ruby_lang_mailing_list_customization/redmine_ext/wiki_formatting'
