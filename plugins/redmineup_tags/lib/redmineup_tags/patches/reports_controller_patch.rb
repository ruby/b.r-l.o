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
  module Patches
    module ReportsControllerPatch
      def self.included(base)
        base.send(:include, InstanceMethods)

        base.class_eval do
          alias_method :issue_report_without_redmine_tags, :issue_report
          alias_method :issue_report, :issue_report_with_redmine_tags

          alias_method :issue_report_details_without_redmine_tags, :issue_report_details
          alias_method :issue_report_details, :issue_report_details_with_redmine_tags
        end
      end

      module InstanceMethods

        def issue_report_with_redmine_tags
          with_subprojects = Setting.display_subprojects_issues?

          @tags = Issue.project_tags(@project)
          @issues_by_tags = Issue.by_tags(@project, with_subprojects)

          issue_report_without_redmine_tags
        end

        def issue_report_details_with_redmine_tags
          with_subprojects = Setting.display_subprojects_issues?

          if params[:detail] == 'tag'
            @field = "tag_id"
            @rows = Issue.project_tags(@project)
            @data = Issue.by_tags(@project, with_subprojects)
            @report_title = l(:field_tags)
          else
            issue_report_details_without_redmine_tags
          end
        end
      end
    end
  end
end

unless ReportsController.included_modules.include?(RedmineupTags::Patches::ReportsControllerPatch)
  ReportsController.send(:include, RedmineupTags::Patches::ReportsControllerPatch)
end
