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
    class ModelIssueHook < Redmine::Hook::ViewListener
      def controller_issues_edit_before_save(context = {})
        tags_log context
      end

      def controller_issues_bulk_edit_before_save(context = {})
        tags_log context
      end

      def tags_log(context, create_journal = true)
        issue = context[:issue]
        params = context[:params]
        if params && params[:issue] && !params[:issue][:tag_list].nil?
          old_tags = Issue.find(issue.id).tag_list.to_s
          new_tags = issue.tag_list.to_s
          if create_journal && !(old_tags == new_tags || issue.current_journal.blank?)
            issue.current_journal.details << JournalDetail.new(property: 'attr',
                                                               prop_key: 'tag_list',
                                                               old_value: old_tags,
                                                               value: new_tags)
          end
        end
      end
    end
  end
end
