# Redmine RD formatter
require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting RD formatter for RedMine'

Redmine::Plugin.register :redmine_rd_formatter do
  name 'RD formatter'
  author 'Yuki Sonoda (Yugui)'
  description 'This provides RD as a wiki format'
  version '0.0.2'
  url 'http://github.com/yugui/redmine_rd_formatter'
  author_url 'http://yugui.jp'

  settings :default => {
    'rd_formatter_require_block' => true
  }, :partial => 'settings/rd_formatter_settings'

  wiki_format_provider 'RD', RedmineRDFormatter::WikiFormatter, RedmineRDFormatter::Helper
end
