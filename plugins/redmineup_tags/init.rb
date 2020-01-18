# This file is a part of Redmine Tags (redmine_tags) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2019 RedmineUP
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

requires_redmine_crm version_or_higher: '0.0.43' rescue raise "\n\033[31mRedmine requires newer redmine_crm gem version.\nPlease update with 'bundle update redmine_crm'.\033[0m"

require 'redmine'

TAGS_VERSION_NUMBER = '2.0.8'
TAGS_VERSION_TYPE = 'Light version'

Redmine::Plugin.register :redmineup_tags do
  name "Redmine Tags plugin (#{TAGS_VERSION_TYPE})"
  author 'RedmineUP'
  description 'Redmine issues tagging support'
  version TAGS_VERSION_NUMBER
  url 'https://www.redmineup.com/pages/tags'
  author_url 'mailto:support@redmineup.com'

  requires_redmine version_or_higher: '2.6'

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

require 'redmineup_tags'
