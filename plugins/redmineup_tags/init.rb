# This file is a part of Redmine Tags (redmine_tags) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2024 RedmineUP
# http://www.redmineup.com/
#
# redmine_tags is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_tags is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_tags.  If not, see <http://www.gnu.org/licenses/>.

requires_redmineup version_or_higher: '1.0.5' rescue raise "\n\033[31mRedmine requires newer redmineup gem version.\nPlease update with 'bundle update redmineup'.\033[0m"

require 'redmine'

TAGS_VERSION_NUMBER = '2.0.14'
TAGS_VERSION_TYPE = 'Light version'

Redmine::Plugin.register :redmineup_tags do
  name "Redmine Tags plugin (#{TAGS_VERSION_TYPE})"
  author 'RedmineUP'
  description 'Redmine issues tagging support'
  version TAGS_VERSION_NUMBER
  url 'https://www.redmineup.com/pages/plugins/tags/'
  author_url 'mailto:support@redmineup.com'

  requires_redmine version_or_higher: '4.0'

  settings default: { issues_sidebar: 'none',
                      issues_show_count: 0,
                      issues_open_only: 0,
                      issues_sort_by: 'name',
                      issues_sort_order: 'asc',
                      tags_suggestion_order: 'name'
                    }, partial: 'tags/settings'

  menu :admin_menu, :tags, { controller: 'settings', action: 'plugin', id: 'redmineup_tags' }, caption: :tags, html: { class: 'icon' }

  project_module :issue_tracking do
    permission :create_tags, {}
    permission :edit_tags, {}
  end
end

if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk
  Rails.autoloaders.each { |loader| loader.ignore(File.dirname(__FILE__) + '/lib') }
end
require File.dirname(__FILE__) + '/lib/redmineup_tags'

ActiveSupport.on_load(:action_view) do
  include TagsHelper
end
