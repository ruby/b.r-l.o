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

require_dependency 'query'

module RedmineupTags
  module Patches
    module TimeReportPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          alias_method :load_available_criteria_without_redmine_tags, :load_available_criteria
          alias_method :load_available_criteria, :load_available_criteria_with_redmine_tags
        end
      end

      module InstanceMethods

        def load_available_criteria_with_redmine_tags
          return @load_available_criteria_with_redmine_tags if @load_available_criteria_with_redmine_tags
          @load_available_criteria_with_redmine_tags = load_available_criteria_without_redmine_tags
          @load_available_criteria_with_redmine_tags['tags'] = { sql: "#{RedmineCrm::Tag.table_name}.id",
                                                                 klass: RedmineCrm::Tag,
                                                                 joins: redmine_tags_join,
                                                                 label: :tags }
          @load_available_criteria_with_redmine_tags
        end

        private

        def redmine_tags_join
          return { issue: :tags } if [Redmine::VERSION::MAJOR, Redmine::VERSION::MINOR] != [3, 4]
          time_entry_table = Arel::Table.new(TimeEntry.table_name)
          issues_table = Arel::Table.new(Issue.table_name, as: :issues_time_entries)
          taggings_table = Arel::Table.new(:taggings)
          tags_table = Arel::Table.new(RedmineCrm::Tag.table_name)
          jn = time_entry_table.join(issues_table).on(issues_table[:id].eq(time_entry_table[:issue_id]))
                .join(taggings_table).on(taggings_table[:taggable_id].eq(issues_table[:id]).and(taggings_table[:taggable_type].eq('Issue')))
                .join(tags_table).on(tags_table[:id].eq(taggings_table[:tag_id]))
                .join_sources
        end
      end
    end
  end
end

unless Redmine::Helpers::TimeReport.included_modules.include?(RedmineupTags::Patches::TimeReportPatch)
  Redmine::Helpers::TimeReport.send(:include, RedmineupTags::Patches::TimeReportPatch)
end
