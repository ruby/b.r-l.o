# frozen_string_literal: true

module RedmineMcp
  module Tools
    class ListIssues < Base
      tool_name 'list_issues'
      description 'Lists issues with structured filters (project, status, tracker, assignee, ' \
                  'author, update date), sorted by last update by default. ' \
                  'For free text search over descriptions and comments use the search tool instead.'
      input_schema(
        {
          type: 'object',
          properties: {
            project: {type: 'string', description: 'Project identifier (see list_projects)'},
            status: {
              type: 'string',
              description: "'open' (default), 'closed', 'any', or a status name such as 'Feedback'"
            },
            tracker: {type: 'string', description: "Tracker name, e.g. 'Bug' or 'Feature'"},
            assigned_to: {
              type: 'string',
              description: "Assignee login or numeric id, 'me' for yourself, or 'none' for unassigned issues"
            },
            author: {type: 'string', description: "Author login or numeric id, or 'me'"},
            subject: {type: 'string', description: 'Words that must appear in the issue subject'},
            updated_after: {type: 'string', description: 'Only issues updated at or after this ISO 8601 date/datetime'},
            created_after: {type: 'string', description: 'Only issues created at or after this ISO 8601 date/datetime'},
            sort: {
              type: 'string',
              enum: %w[updated_on created_on id],
              description: 'Sort field, descending. Default: updated_on'
            },
            limit: {type: 'integer', description: 'Maximum number of results (default 25, max 100)'},
            offset: {type: 'integer', description: 'Number of results to skip, for pagination'}
          },
          required: []
        }
      )

      SORT_COLUMNS = %w[updated_on created_on id].freeze

      def call(args)
        limit, offset = pagination(args)
        scope = Issue.visible(user)
        scope = apply_filters(scope, args)

        sort = args['sort'].presence || 'updated_on'
        fail!("Invalid sort: #{sort}. Available: #{SORT_COLUMNS.join(', ')}") unless SORT_COLUMNS.include?(sort)

        {
          total_count: scope.count,
          offset: offset,
          limit: limit,
          issues: scope.order(sort => :desc, :id => :desc).offset(offset).limit(limit).
                    preload(:project, :tracker, :status, :priority, :author, :assigned_to).
                    map {|issue| issue_summary(issue)}
        }
      end

      private

      def apply_filters(scope, args)
        if args['project'].present?
          scope = scope.where(project_id: find_project!(args['project']).id)
        end

        case (status = args['status'].to_s.strip.presence || 'open')
        when 'open'
          scope = scope.open
        when 'closed'
          scope = scope.open(false)
        when 'any', 'all', '*'
          # no filter
        else
          scope = scope.where(status_id: resolve_status!(status).id)
        end

        if args['tracker'].present?
          scope = scope.where(tracker_id: resolve_tracker!(args['tracker']).id)
        end

        case args['assigned_to'].to_s.strip
        when ''
          # no filter
        when 'me'
          scope = scope.assigned_to(user)
        when 'none'
          scope = scope.where(assigned_to_id: nil)
        else
          scope = scope.assigned_to(resolve_principal!(args['assigned_to']))
        end

        if args['author'].present?
          author = args['author'].to_s.strip == 'me' ? user : resolve_principal!(args['author'])
          scope = scope.where(author_id: author.id)
        end

        scope = scope.like(args['subject'].to_s) if args['subject'].present?

        if args['updated_after'].present?
          scope = scope.where("#{Issue.table_name}.updated_on >= ?", parse_time!(args['updated_after'], 'updated_after'))
        end
        if args['created_after'].present?
          scope = scope.where("#{Issue.table_name}.created_on >= ?", parse_time!(args['created_after'], 'created_after'))
        end
        scope
      end
    end
  end
end
