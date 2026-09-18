# frozen_string_literal: true

module RedmineMcp
  module Tools
    class UnlinkChangeset < Base
      tool_name 'unlink_changeset'
      description 'Removes the link between a repository commit and an issue, undoing a ' \
                  'link_changeset call or dropping a link the commit scanner made from a reference ' \
                  'keyword. Requires the manage_related_issues permission in the project the ' \
                  'repository belongs to. The commit itself is kept. get_issue reports the current ' \
                  'links in changesets.'
      input_schema(
        {
          type: 'object',
          properties: {
            issue_id: {type: 'integer', description: 'Issue to unlink the commit from'},
            revision: {
              type: 'string',
              description: 'Commit revision, as get_issue reports it. A git SHA may be abbreviated ' \
                           'as long as it stays unambiguous.'
            },
            project: {
              type: 'string',
              description: 'Project identifier of the repository. Only needed when the revision ' \
                           'matches a commit in more than one project.'
            },
            repository: {
              type: 'string',
              description: 'Repository identifier, for a project holding several repositories'
            }
          },
          required: %w[issue_id revision]
        }
      )

      def call(args)
        issue = find_issue!(args['issue_id'], field: 'issue_id')
        changeset = find_changeset!(args['revision'], project: args['project'], repository: args['repository'])
        authorize_related_issues!(changeset)

        already = !changeset.issues.include?(issue)
        changeset.issues.delete(issue) unless already
        changeset_link_summary(changeset, issue, already: already, verb: :unlinked)
      end
    end
  end
end
