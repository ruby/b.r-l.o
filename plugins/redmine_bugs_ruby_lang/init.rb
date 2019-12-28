require 'redmine'
require 'redmine_link_to_root'

Redmine::Plugin.register :redmine_link_to_root do
  name 'Redmine Link To Root plugin'
  author 'Yuki Sonoda (Yugui)'
  description <<-EOS.gsub(/^\s+/, '')
    This plugin makes the header title linked to the root of site when it is not associated with any particular project.
    This plugin is developed for https://bugs.ruby-lang.org.
  EOS
  version '0.1.0'
  url 'https://github.com/ruby/redmine_link_to_root'
  author_url 'http://yugui.jp'
end

require 'redmine'

require "redmine_mailing_list_integration"
require "redmine_mailing_list_integration/configuration"

class Redmine::Plugin
  include RedmineMailingListIntegration::Configuration
end

Redmine::Plugin.register :redmine_mailing_list_integration do
  name 'Redmine Mailing List Integration plugin'
  author 'Yuki Sonoda (Yugui)'
  description 'This plugin integrates mailing lists with Redmine'
  version '0.0.1'
  url 'http://github.com/yugui/redmine_mailing_list_integration'
  author_url 'http://yugui.jp'

  requires_redmine version_or_higher: '1.1.0'

  mailing_list_integration do
    driver :fml, RedmineMailingListIntegration::Drivers::FmlDriver
    driver :mailman, RedmineMailingListIntegration::Drivers::MailmanDriver
    driver :quickml, RedmineMailingListIntegration::Drivers::QuickMLDriver
    driver :qwik, RedmineMailingListIntegration::Drivers::QwikDriver
    receptor :dumb, RedmineMailingListIntegration::Receptors::DumbReceptor
    receptor :default, RedmineMailingListIntegration::Receptors::DefaultReceptor
  end
end

require "redmine_mailing_list_integration/hooks"
require 'redmine_mailing_list_integration/redmine_ext'

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :mailing_lists, {controller: 'mailing_lists'}, caption: :label_mailing_list_plural
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'use_of_mailng_list', 'uses_of_mailing_list'
end

require 'redmine'

Redmine::Plugin.register :redmine_mailing_list_integration_imap_supplement do
  name 'Redmine Mailing List Integration IMAP Supplement plugin'
  author 'Yuki Sonoda'
  description 'This plugin adds a IMAP support for Redmine Mailing List Integration plugin'
  version '0.0.1'
  url 'http://github.com/yugui/redmine_mailing_list_integration_imap_supplement'
  author_url 'http://yugui.jp'

  requires_redmine_plugin :redmine_mailing_list_integration, version_or_higher: '0.0.1'
  menu :project_menu, :mail_to_issue, {controller: 'mail_to_issue', action: 'new'}
  project_module :mail_to_issue do
    permission :mail_to_issue, mail_to_issue: %w[ new create ]
  end
end

require 'redmine_mailing_list_integration_imap_supplement/imap'

require 'redmine'
require 'redmine_ruby_lang_mailing_list_customization/ruby_core_or_ruby_dev_receptor'
require "redmine_ruby_lang_mailing_list_customization/hooks"
require 'redmine_ruby_lang_mailing_list_customization/redmine_ext'

Redmine::Plugin.register :redmine_ruby_lang_mailing_list_customization do
  name 'Redmine Ruby Lang Mailing List Customization plugin'
  author 'Yuki Sonoda (Yugui)'
  description 'This is an enhancement for RedmineMailingListIntegration plugin. It adds some ruby-lang.org specific features'
  version '0.0.1'
  url 'http://github.com/yugui/redmine_ruby_lang_mailing_list_customization'
  author_url 'http://yugui.jp'

  requires_redmine version_or_higher: '1.1.0'
  requires_redmine_plugin :redmine_mailing_list_integration, version_or_higher: '0.0.1'

  mailing_list_integration do
    receptor :ruby_core_or_ruby_dev, RedmineRubyLangMailingListCustomization::RubyCoreOrRubyDevReceptor
  end
end
