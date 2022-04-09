# This file is a part of Redmine Tags (redmine_tags) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2021 RedmineUP
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

require_dependency 'issue'

module RedmineupTags
  module Patches
    module IssuePatch

      def self.included(base)
        base.extend(ClassMethods)

        base.class_eval do
          include InstanceMethods

          unloadable
          rcrm_acts_as_taggable

          alias_method :safe_attributes_without_safe_tags=, :safe_attributes=
          alias_method :safe_attributes=, :safe_attributes_with_safe_tags=

          class << self
            alias_method :available_tags_without_redmine_tags, :available_tags
            alias_method :available_tags, :available_tags_with_redmine_tags

            if Redmine::VERSION.to_s <= '2.7'
              alias_method :count_and_group_by_without_redmine_tags, :count_and_group_by
              alias_method :count_and_group_by, :count_and_group_by_with_redmine_tags
            end
          end

          alias_method :copy_from_without_redmine_tags, :copy_from
          alias_method :copy_from, :copy_from_with_redmine_tags

          scope :on_project, lambda { |project|
            project = project.id if project.is_a? Project
            { conditions: ["#{Project.table_name}.id=?", project] }
          }
        end
      end

      # Class used to represent the tags relations of an issue
      class TagsRelations < IssueRelation::Relations
        def to_s(*args)
          map(&:name).join(', ')
        end
      end

      module ClassMethods
        def available_tags_with_redmine_tags(options = {})
          scope = available_tags_without_redmine_tags(options)
          return scope unless options[:open_only]
          scope.joins("JOIN #{IssueStatus.table_name} ON #{IssueStatus.table_name}.id = #{table_name}.status_id").
                where("#{IssueStatus.table_name}.is_closed = ?", false)
        end

        def all_tags(options = {})
          scope = RedmineCrm::Tag.where({})
          scope = scope.where("LOWER(#{RedmineCrm::Tag.table_name}.name) LIKE LOWER(?)", "%#{options[:name_like]}%") if options[:name_like]
          join = []
          join << "JOIN #{RedmineCrm::Tagging.table_name} ON #{RedmineCrm::Tagging.table_name}.tag_id = #{RedmineCrm::Tag.table_name}.id "
          join << "JOIN #{Issue.table_name} ON #{Issue.table_name}.id = #{RedmineCrm::Tagging.table_name}.taggable_id
            AND #{RedmineCrm::Tagging.table_name}.taggable_type = '#{Issue.name}' "
          scope = scope.joins(join.join(' '))

          columns = [
            "#{RedmineCrm::Tag.table_name}.*",
            "COUNT(DISTINCT #{RedmineCrm::Tagging.table_name}.taggable_id) AS count"
          ]
          if options[:sort_by] == 'created_at'
            columns << "MIN(#{RedmineCrm::Tagging.table_name}.created_at) AS created_at"
          end
          scope = scope.select(columns.join(', '))

          scope = scope.group("#{RedmineCrm::Tag.table_name}.id, #{RedmineCrm::Tag.table_name}.name ")
          scope = scope.having('COUNT(*) > 0')

          column = options[:sort_by] || "#{RedmineCrm::Tag.table_name}.name"
          order = options[:order] || 'ASC'
          scope.order("#{column} #{order}")
        end

        def project_tags(project)
          all_tags.where("#{Issue.table_name}.project_id = #{project.id}")
        end

        def allowed_tags?(tags)
          allowed_tags = all_tags.map(&:name)
          tags.all? { |tag| allowed_tags.include?(tag) }
        end

        def by_tags(project, with_subprojects=false)
          count_and_group_by(project: project, association: :tags, with_subprojects: with_subprojects)
        end

        def count_and_group_by_with_redmine_tags(options)
          return count_and_group_by_without_redmine_tags(options) unless options[:association] == :tags

          assoc = reflect_on_association(options[:association])
          select_field = assoc.foreign_key

          Issue.
            visible(User.current, :project => options[:project], :with_subprojects => options[:with_subprojects]).
            joins(:status, assoc.name).
            group(:status_id, :is_closed, select_field).
            count.
            map do |columns, total|
              status_id, is_closed, field_value = columns
              is_closed = ['t', 'true', '1'].include?(is_closed.to_s)
              {
                "status_id" => status_id.to_s,
                "closed" => is_closed,
                select_field => field_value.to_s,
                "total" => total.to_s
              }
            end
        end
      end

      module InstanceMethods
        def safe_attributes_with_safe_tags=(attrs, user = User.current)
          self.send(:safe_attributes_without_safe_tags=, attrs, user)
          if attrs && attrs[:tag_list] && user.allowed_to?(:edit_tags, project)
            tags = attrs[:tag_list].reject(&:empty?)
            if user.allowed_to?(:create_tags, project) || Issue.allowed_tags?(tags)
              self.tag_list = tags
            end
          end
        end

        def tags_relations
          TagsRelations.new(self, tags.to_a)
        end

        def copy_from_with_redmine_tags(arg, options={})
          original_issue = arg.is_a?(Issue) ? arg : Issue.visible.find(arg)
          copied_issue = copy_from_without_redmine_tags(original_issue, options)
          copied_issue.tags = original_issue.tags
          copied_issue
        end
      end
    end
  end
end

unless Issue.included_modules.include?(RedmineupTags::Patches::IssuePatch)
  Issue.send(:include, RedmineupTags::Patches::IssuePatch)
end
