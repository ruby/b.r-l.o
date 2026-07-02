# frozen_string_literal: true

module RedmineMcp
  module Tools
    class CreateIssue < Base
      tool_name 'create_issue'
      description 'Creates a new issue. Requires the add_issues permission in the target project. ' \
                  'Use project_metadata first to discover valid trackers, priorities, categories, ' \
                  'versions and assignees. The description uses the wiki text formatting reported by whoami.'
      input_schema(
        {
          type: 'object',
          properties: {
            project: {type: 'string', description: 'Project identifier (see list_projects)'},
            subject: {type: 'string', description: 'Issue subject (one line)'},
            description: {type: 'string', description: 'Issue description'},
            tracker: {type: 'string', description: "Tracker name, e.g. 'Bug' or 'Feature'. Default: the project's first tracker"},
            priority: {type: 'string', description: 'Priority name. Default: the default priority'},
            assigned_to: {type: 'string', description: 'Assignee login or numeric id'},
            category: {type: 'string', description: 'Issue category name'},
            version: {type: 'string', description: 'Target version name'},
            custom_fields: {
              type: 'object',
              description: 'Custom field values keyed by field name, ' \
                           "e.g. {\"ruby -v\": \"ruby 3.4.0\", \"Backport\": \"3.3: REQUIRED\"}",
              additionalProperties: {type: 'string'}
            }
          },
          required: %w[project subject]
        }
      )

      def call(args)
        project = find_project!(args['project'])
        fail!("You are not allowed to create issues in #{project.identifier}") unless user.allowed_to?(:add_issues, project)
        fail!('Missing required argument: subject') if args['subject'].blank?

        issue = Issue.new(project: project, author: user)
        issue.send(:safe_attributes=, build_attributes(project, args), user)

        if issue.save
          {created: true}.merge(issue_summary(issue))
        else
          fail!("Issue could not be created: #{issue.errors.full_messages.join(', ')}")
        end
      end

      private

      def build_attributes(project, args)
        attrs = {
          'subject' => args['subject'].to_s,
          'description' => args['description'].to_s
        }
        attrs['tracker_id'] = resolve_tracker!(project, args['tracker']).id if args['tracker'].present?
        attrs['priority_id'] = resolve_priority!(args['priority']).id if args['priority'].present?
        attrs['assigned_to_id'] = resolve_principal!(args['assigned_to']).id if args['assigned_to'].present?
        if args['category'].present?
          category = project.issue_categories.detect {|c| c.name.casecmp?(args['category'].to_s.strip)}
          category || fail!("Unknown category: #{args['category']}. Available: #{project.issue_categories.map(&:name).join(', ')}")
          attrs['category_id'] = category.id
        end
        if args['version'].present?
          version = project.shared_versions.detect {|v| v.name.casecmp?(args['version'].to_s.strip)}
          version || fail!("Unknown version: #{args['version']}. Available: #{project.shared_versions.map(&:name).join(', ')}")
          attrs['fixed_version_id'] = version.id
        end
        if args['custom_fields'].is_a?(Hash)
          attrs['custom_field_values'] = custom_field_values(project, args['custom_fields'])
        end
        attrs
      end

      def custom_field_values(project, fields)
        available = project.all_issue_custom_fields
        fields.each_with_object({}) do |(name, value), values|
          field = available.detect {|f| f.name.casecmp?(name.to_s.strip)}
          field || fail!("Unknown custom field: #{name}. Available: #{available.map(&:name).join(', ')}")
          values[field.id.to_s] = value
        end
      end
    end
  end
end
