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
