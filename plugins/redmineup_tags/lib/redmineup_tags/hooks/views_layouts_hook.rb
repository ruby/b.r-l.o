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

module RedmineupTags
  module Hooks
    class ViewsLayoutsHook < Redmine::Hook::ViewListener

      def view_layouts_base_html_head(context = {})
        javascript_include_tag "redmine_tags", :plugin => 'redmineup_tags'
        javascript_include_tag 'select2', plugin: 'redmine_crm'
        javascript_include_tag 'select2_helpers', plugin: 'redmine_crm'
        stylesheet_link_tag "redmine_tags", :plugin => 'redmineup_tags'
        stylesheet_link_tag 'select2', plugin: 'redmine_crm'
      end

      def view_layouts_base_body_bottom(context = {})
        options = {url: auto_complete_redmine_tags_url}
        javascript_tag("setSelect2Filter('issue_tags', #{options.to_json});")
      end

    end
  end
end
