# frozen_string_literal: true

module RedmineMcp
  module Tools
    class UpdateJournal < Base
      tool_name 'update_journal'
      description 'Rewrites an existing comment (journal note) on an issue. The notes argument ' \
                  'REPLACES the whole comment text: it is not appended, and the text it overwrites ' \
                  'is not recoverable through this API, so read the current text with get_issue and ' \
                  'send it back edited. Use update_issue to add a new comment instead. Journal ids ' \
                  'come from the id field of the journals entries returned by get_issue. Editing ' \
                  'your own comment requires the edit_own_issue_notes permission, editing anyone ' \
                  "else's requires edit_issue_notes."
      input_schema(
        {
          type: 'object',
          properties: {
            journal_id: {
              type: 'integer',
              description: 'Journal id of the comment to rewrite, from get_issue (journals[].id). ' \
                           'This is not the issue id.'
            },
            notes: {
              type: 'string',
              description: 'Full replacement text of the comment, in the wiki text formatting ' \
                           'reported by whoami'
            },
            private_notes: {
              type: 'boolean',
              description: 'Change the visibility of the comment. True restricts it to users allowed ' \
                           'to view private notes, false makes it visible to everyone who can see ' \
                           'the issue. Requires the set_notes_private permission.'
            }
          },
          required: ['journal_id']
        }
      )

      def call(args)
        journal = find_journal!(args['journal_id'])

        wants_notes = args.key?('notes')
        wants_privacy = args.key?('private_notes')
        fail!('Nothing to do: provide notes and/or private_notes') unless wants_notes || wants_privacy
        if wants_notes && args['notes'].blank?
          fail!('notes cannot be empty: this tool rewrites a comment and cannot delete one')
        end
        fail!(edit_error(journal)) unless journal.editable_by?(user)
        # safe_attributes= silently drops private_notes without this permission,
        # which would leave the comment at its current visibility
        if wants_privacy && !user.allowed_to?(:set_notes_private, journal.project)
          fail!('You are not allowed to change the visibility of comments on issue ' \
                "##{journal.issue.id}: it needs the set_notes_private permission")
        end

        attrs = {'updated_by' => user}
        attrs['notes'] = args['notes'].to_s if wants_notes
        attrs['private_notes'] = args['private_notes'] ? true : false if wants_privacy
        journal.send(:safe_attributes=, attrs, user)

        if journal.save
          {
            updated: true,
            journal_id: journal.id,
            issue_id: journal.issue.id,
            private_notes: journal.private_notes?,
            notes: journal.notes,
            url: base_url("/issues/#{journal.issue.id}#change-#{journal.id}")
          }
        else
          fail!("Comment could not be updated: #{journal.errors.full_messages.join(', ')}")
        end
      end

      private

      # Journal.visible also hides private notes the user may not read, so an
      # invisible journal is reported the same way an invisible issue is
      def find_journal!(id)
        fail!('Missing required argument: journal_id') if id.blank?

        Journal.visible(user).find_by_id(id.to_i) ||
          fail!("Comment #{id} not found or not visible to you")
      end

      def edit_error(journal)
        if journal.user_id == user.id
          "You are not allowed to edit your own comments on issue ##{journal.issue.id}: " \
            'it needs the edit_own_issue_notes permission'
        else
          "Comment #{journal.id} was written by #{journal.user&.name || 'another user'}; " \
            "editing it on issue ##{journal.issue.id} needs the edit_issue_notes permission"
        end
      end
    end
  end
end
