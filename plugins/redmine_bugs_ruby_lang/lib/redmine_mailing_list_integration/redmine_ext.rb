require 'redmine_mailing_list_integration/redmine_ext/issue'

Journal.class_eval do
  include BasedOnMail
end

require 'redmine_mailing_list_integration/redmine_ext/mail_handler'
require 'redmine_mailing_list_integration/redmine_ext/mailer'
require 'redmine_mailing_list_integration/redmine_ext/project'
