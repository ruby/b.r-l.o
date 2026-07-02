# frozen_string_literal: true

module RedmineMcp
  module Tools
    class UpdateIssue < Base
      tool_name 'update_issue'
      description 'Adds a comment to an issue and/or changes its attributes ' \
                  '(status, assignee, priority, subject, description, category, version, done ratio). ' \
                  'Status changes are validated against the workflow; on rejection the error lists ' \
                  'the transitions available to you.'
      input_schema(
        {
          type: 'object',
          properties: {
            id: {type: 'integer', description: 'Issue id'},
            notes: {type: 'string', description: 'Comment to add, in the wiki text formatting reported by whoami'},
            private_notes: {type: 'boolean', description: 'Make the comment visible only to users allowed to view private notes'},
            status: {type: 'string', description: "New status name, e.g. 'Closed' or 'Feedback'"},
            assigned_to: {type: 'string', description: "New assignee login or numeric id, or 'none' to unassign"},
            priority: {type: 'string', description: 'New priority name'},
            subject: {type: 'string', description: 'New subject'},
            description: {type: 'string', description: 'New description (replaces the current one)'},
            category: {type: 'string', description: 'New category name'},
            version: {type: 'string', description: "New target version name, or 'none' to clear"},
            done_ratio: {type: 'integer', description: 'Percent done, 0-100'}
          },
          required: ['id']
        }
      )

      ATTRIBUTE_KEYS = %w[status assigned_to priority subject description category version done_ratio].freeze

      def call(args)
        issue = find_issue!(args['id'])

        wants_notes = args['notes'].present?
        wants_attributes = ATTRIBUTE_KEYS.any? {|key| args.key?(key)}
        fail!('Nothing to do: provide notes and/or attributes to change') unless wants_notes || wants_attributes

        if wants_notes && !issue.notes_addable?(user)
          fail!("You are not allowed to add notes to issue ##{issue.id}")
        end
        if wants_attributes && !issue.attributes_editable?(user)
          fail!("You are not allowed to edit issue ##{issue.id}")
        end

        issue.init_journal(user, args['notes'].to_s)
        issue.send(:safe_attributes=, build_attributes(issue, args), user)

        if issue.save
          {updated: true}.merge(issue_summary(issue))
        else
          fail!("Issue could not be updated: #{issue.errors.full_messages.join(', ')}")
        end
      end

      private

      def build_attributes(issue, args)
        project = issue.project
        attrs = {}
        attrs['private_notes'] = true if args['private_notes'] && args['notes'].present?
        attrs['status_id'] = new_status_id(issue, args['status']) if args['status'].present?
        attrs['subject'] = args['subject'].to_s if args.key?('subject')
        attrs['description'] = args['description'].to_s if args.key?('description')
        attrs['priority_id'] = resolve_priority!(args['priority']).id if args['priority'].present?
        attrs['done_ratio'] = args['done_ratio'].to_i if args.key?('done_ratio')

        case args['assigned_to'].to_s.strip
        when ''
          # not requested
        when 'none'
          attrs['assigned_to_id'] = ''
        else
          attrs['assigned_to_id'] = resolve_principal!(args['assigned_to']).id
        end

        attrs['category_id'] = resolve_category!(project, args['category']).id if args['category'].present?

        case args['version'].to_s.strip
        when ''
          # not requested
        when 'none'
          attrs['fixed_version_id'] = ''
        else
          attrs['fixed_version_id'] = resolve_version!(project, args['version']).id
        end

        attrs
      end

      def new_status_id(issue, value)
        status = resolve_status!(value)
        return status.id if status.id == issue.status_id

        allowed = issue.new_statuses_allowed_to(user)
        unless allowed.include?(status)
          fail!("Cannot change status of ##{issue.id} from '#{issue.status.name}' to '#{status.name}'. " \
                "Transitions allowed to you: #{allowed.map(&:name).join(', ')}")
        end
        status.id
      end
    end
  end
end
