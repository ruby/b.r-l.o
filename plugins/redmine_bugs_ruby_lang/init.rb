require 'redmine'
require 'redmine_link_to_root'
require "redmine_mailing_list_integration"
require "redmine_mailing_list_integration/configuration"
require "redmine_mailing_list_integration/hooks"
require 'redmine_mailing_list_integration/redmine_ext'
require 'redmine_mailing_list_integration_imap_supplement/imap'
require 'redmine_ruby_lang_mailing_list_customization/ruby_core_or_ruby_dev_receptor'
require "redmine_ruby_lang_mailing_list_customization/hooks"
require 'redmine_ruby_lang_mailing_list_customization/redmine_ext'

Redmine::Plugin.register :redmine_bugs_ruby_lang do
  name 'Redmine Link To Root plugin'
  author 'Yuki Sonoda (Yugui)'
  description <<-EOS.gsub(/^\s+/, '')
    This plugin makes the header title linked to the root of site when it is not associated with any particular project.
    This plugin integrates mailing lists with Redmine
    This plugin adds a IMAP support for Redmine Mailing List Integration plugin
    This is an enhancement for RedmineMailingListIntegration plugin. It adds some ruby-lang.org specific features
    This plugin is developed for https://bugs.ruby-lang.org.
  EOS
  version '1.0.0'
  url 'https://github.com/ruby/b.r-l.o'
  author_url 'https://github.com/ruby/b.r-l.o'

  requires_redmine version_or_higher: '1.1.0'

  menu :project_menu, :mail_to_issue, {controller: 'mail_to_issue', action: 'new'}
  project_module :mail_to_issue do
    permission :mail_to_issue, mail_to_issue: %w[ new create ]
  end

  mailing_list_integration do
    driver :fml, RedmineMailingListIntegration::Drivers::FmlDriver
    driver :mailman, RedmineMailingListIntegration::Drivers::MailmanDriver
    driver :quickml, RedmineMailingListIntegration::Drivers::QuickMLDriver
    driver :qwik, RedmineMailingListIntegration::Drivers::QwikDriver
    receptor :dumb, RedmineMailingListIntegration::Receptors::DumbReceptor
    receptor :default, RedmineMailingListIntegration::Receptors::DefaultReceptor
    receptor :ruby_core_or_ruby_dev, RedmineRubyLangMailingListCustomization::RubyCoreOrRubyDevReceptor
  end
end

class Redmine::Plugin
  include RedmineMailingListIntegration::Configuration
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :mailing_lists, {controller: 'mailing_lists'}, caption: :label_mailing_list_plural
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'use_of_mailng_list', 'uses_of_mailing_list'
end
