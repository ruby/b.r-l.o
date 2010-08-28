require 'redmine'
require 'redmine_link_to_root/extension'

Redmine::Plugin.register :redmine_link_to_root do
  name 'Redmine Link To Root plugin'
  author 'Yuki Sonoda (Yugui)'
  description <<-EOS.gsub(/^\s+/, '')
    This plugin makes the header title linked to the root of site when it is not associated with any particular project.
    This plugin is developed for http://redmine.ruby-lang.org.
  EOS
  version '0.0.1'
  url 'http://github.com/yugui/redmine_link_to_root'
  author_url 'http://yugui.jp'
end

ApplicationController.class_eval do
  include RedmineLinkToRoot::Extension
end
