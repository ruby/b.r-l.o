require 'redmine'

require_dependency 'redmine_ruby_lang_mailing_list_customization/ruby_core_or_ruby_dev_receptor'

require_dependency "redmine_ruby_lang_mailing_list_customization/hooks"
Redmine::Plugin.register :redmine_ruby_lang_mailing_list_customization do
  name 'Redmine Ruby Lang Mailing List Customization plugin'
  author 'Yuki Sonoda (Yugui)'
  description 'This is an enhancement for RedmineMailingListIntegration plugin. It adds some ruby-lang.org specific features'
  version '0.0.1'
  url 'http://github.com/yugui/redmine_ruby_lang_mailing_list_customization'
  author_url 'http://yugui.jp'

  requires_redmine :version_or_higher => '1.1.0'
  requires_redmine_plugin :redmine_mailing_list_integration, :version_or_higher => '0.0.1'

  mailing_list_integration do
    receptor :ruby_core_or_ruby_dev, RedmineRubyLangMailingListCustomization::RubyCoreOrRubyDevReceptor
  end
end

dir = File.expand_path("lib/redmine_ruby_lang_mailing_list_customization/redmine_ext", File.dirname(__FILE__))
Dir.glob( File.join(dir, '*.rb') ) do |path|
  require_dependency path
end
