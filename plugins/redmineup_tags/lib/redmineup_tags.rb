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

module RedmineupTags
  def self.settings() Setting[:plugin_redmineup_tags].stringify_keys end
end

REDMINEUP_TAGS_REQUIRED_FILES = [
  'redmineup_tags/hooks/model_issue_hook',
  'redmineup_tags/hooks/views_context_menus_hook',
  'redmineup_tags/hooks/views_issues_hook',
  'redmineup_tags/hooks/views_layouts_hook',
  'redmineup_tags/patches/add_helpers_for_issue_tags_patch',
  'redmineup_tags/patches/auto_completes_controller_patch',
  'redmineup_tags/patches/issue_patch',
  'redmineup_tags/patches/issue_query_patch',
  'redmineup_tags/patches/queries_helper_patch',
  'redmineup_tags/patches/time_entry_query_patch',
  'redmineup_tags/patches/time_report_patch',
  'redmineup_tags/patches/time_entry_patch',
  'query_tags_column',
  'redmineup_tags/patches/reports_controller_patch',
  'redmineup_tags/hooks/views_reports_hook',
]

if Redmine::Plugin.installed?(:redmine_agile) &&
  Gem::Version.new(Redmine::Plugin.find(:redmine_agile).version) >= Gem::Version.new('1.4.3') && AGILE_VERSION_TYPE == 'PRO version'
  REDMINEUP_TAGS_REQUIRED_FILES << 'redmineup_tags/patches/agile_query_patch'
  REDMINEUP_TAGS_REQUIRED_FILES << 'redmineup_tags/patches/agile_versions_query_patch'
end

base_url = File.dirname(__FILE__)
REDMINEUP_TAGS_REQUIRED_FILES.each { |file| require(base_url + '/' + file) }
