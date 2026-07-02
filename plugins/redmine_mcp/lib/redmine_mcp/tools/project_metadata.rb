# frozen_string_literal: true

module RedmineMcp
  module Tools
    class ProjectMetadata < Base
      tool_name 'project_metadata'
      description 'Returns the valid values for issue fields in a project: trackers, ' \
                  'statuses, priorities, categories, target versions and assignable users. ' \
                  'Call this before creating or updating issues.'
      input_schema(
        {
          type: 'object',
          properties: {
            project: {type: 'string', description: 'Project identifier (see list_projects)'}
          },
          required: ['project']
        }
      )

      ASSIGNEE_LIMIT = 200

      def call(args)
        project = find_project!(args['project'])
        assignees = project.assignable_users.sorted.to_a

        {
          project: project.identifier,
          trackers: project.trackers.sorted.map(&:name),
          statuses: IssueStatus.sorted.map {|s| {name: s.name, closed: s.is_closed?}},
          priorities: IssuePriority.active.map {|p| {name: p.name, default: p.is_default?}},
          categories: project.issue_categories.map(&:name),
          versions: project.shared_versions.sorted.map {|v| {name: v.name, status: v.status}},
          assignable_users: assignees.first(ASSIGNEE_LIMIT).map {|u| assignee_hash(u)},
          assignable_users_truncated: assignees.size > ASSIGNEE_LIMIT,
          permissions: {
            add_issues: user.allowed_to?(:add_issues, project),
            edit_issues: user.allowed_to?(:edit_issues, project),
            add_issue_notes: user.allowed_to?(:add_issue_notes, project),
            edit_wiki_pages: user.allowed_to?(:edit_wiki_pages, project)
          }
        }
      end

      private

      def assignee_hash(principal)
        hash = {id: principal.id, name: principal.name}
        hash[:login] = principal.login if principal.is_a?(User)
        hash
      end
    end
  end
end
