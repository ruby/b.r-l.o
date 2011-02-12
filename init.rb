require 'redmine'
require 'redmine/plugin'
require_dependency "redmine_mailing_list_integration/configuration"
class Redmine::Plugin
  include RedmineMailingListIntegration::Configuration
end

require_dependency "redmine_mailing_list_integration/hooks"
Redmine::Plugin.register :redmine_mailing_list_integration do
  name 'Redmine Mailing List Integration plugin'
  author 'Yuki Sonoda (Yugui)'
  description 'This plugin integrates mailing lists with Redmine'
  version '0.0.1'
  url 'http://github.com/yugui/redmine_mailing_list_integration'
  author_url 'http://yugui.jp'

  requires_redmine :version_or_higher => '1.1.0'

  mailing_list_integration do
    driver :fml, RedmineMailingListIntegration::Drivers::FmlDriver
    receptor :dumb, RedmineMailingListIntegration::Receptors::DumbReceptor
    receptor :default, RedmineMailingListIntegration::Receptors::DefaultReceptor
  end
end

Redmine::MenuManager.map :admin_menu do |menu|
  menu.push :mailing_lists, {:controller => 'mailing_lists'}, :caption => :label_mailing_list_plural
end

dir = File.expand_path("lib/redmine_mailing_list_integration/redmine_ext", File.dirname(__FILE__))
Dir.glob( File.join(dir, '*.rb') ) do |path|
  require_dependency path
end

ActiveSupport::Inflector.inflections do |inflect|
  inflect.irregular 'use_of_mailng_list', 'uses_of_mailing_list'
end
