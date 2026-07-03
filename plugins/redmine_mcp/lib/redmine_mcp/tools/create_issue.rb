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
        attrs['tracker_id'] = resolve_tracker!(args['tracker'], project: project).id if args['tracker'].present?
        attrs['priority_id'] = resolve_priority!(args['priority']).id if args['priority'].present?
        attrs['assigned_to_id'] = resolve_principal!(args['assigned_to']).id if args['assigned_to'].present?
        attrs['category_id'] = resolve_category!(project, args['category']).id if args['category'].present?
        attrs['fixed_version_id'] = resolve_version!(project, args['version']).id if args['version'].present?
        if args['custom_fields'].is_a?(Hash)
          attrs['custom_field_values'] = custom_field_values!(project, args['custom_fields'])
        end
        attrs
      end
    end
  end
end
