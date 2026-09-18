# frozen_string_literal: true

module RedmineMcp
  module Tools
    class LinkChangeset < Base
      tool_name 'link_changeset'
      description 'Links a repository commit to an issue, the same way the "Associated revisions" ' \
                  'section of the revision page does. Requires the manage_related_issues permission ' \
                  'in the project the repository belongs to. Use it when a commit was pushed without ' \
                  'a reference keyword in its message, so Redmine never linked it. Only commits ' \
                  'Redmine has already fetched can be linked. This writes the link alone: it does ' \
                  'not change the status, add a comment or log time, which update_issue does. ' \
                  'get_issue reports the current links in changesets, and unlink_changeset removes one.'
      input_schema(
        {
          type: 'object',
          properties: {
            issue_id: {type: 'integer', description: 'Issue to link the commit to'},
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

        return changeset_link_summary(changeset, issue, already: true) if changeset.issues.include?(issue)

        referenceable!(changeset, issue)
        begin
          changeset.issues << issue
        rescue ActiveRecord::RecordNotUnique
          # lost the race with a concurrent link, which is the state asked for
        end
        changeset_link_summary(changeset, issue)
      end

      private

      # The commit scanner only links an issue its repository's project tree
      # owns unless cross-project references are enabled, and silently drops
      # the rest. Refusing the same pairs keeps this tool from writing a link
      # that a repository re-scan would never reproduce.
      def referenceable!(changeset, issue)
        return if changeset.find_referenced_issue_by_id(issue.id)

        fail!("Issue ##{issue.id} belongs to #{issue.project.identifier}, which is outside the project tree of " \
              "the #{changeset.project.identifier} repository, and cross-project issue references are disabled " \
              'in Administration > Settings > Repositories.')
      end
    end
  end
end
