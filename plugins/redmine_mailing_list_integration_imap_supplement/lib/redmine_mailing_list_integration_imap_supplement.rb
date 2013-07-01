require 'redmine'

Redmine::Plugin.register :redmine_mailing_list_integration_imap_supplement do
  name 'Redmine Mailing List Integration IMAP Supplement plugin'
  author 'Yuki Sonoda'
  description 'This plugin adds a IMAP support for Redmine Mailing List Integration plugin'
  version '0.0.1'
  url 'http://github.com/yugui/redmine_mailing_list_integration_imap_supplement'
  author_url 'http://yugui.jp'

  requires_redmine_plugin :redmine_mailing_list_integration, :version_or_higher => '0.0.1'
  menu :project_menu, :mail_to_issue, {:controller => 'mail_to_issue', :action => 'new'}
  project_module :mail_to_issue do
    permission :mail_to_issue, :mail_to_issue => %w[ new create ]
  end
end

dir = File.expand_path("lib/redmine_mailing_list_integration_imap_supplement/redmine_ext", File.dirname(__FILE__))
Dir.glob( File.join(dir, '*.rb') ) do |path|
  require_dependency path
end
