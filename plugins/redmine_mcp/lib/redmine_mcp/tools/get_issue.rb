# frozen_string_literal: true

module RedmineMcp
  module Tools
    class GetIssue < Base
      tool_name 'get_issue'
      description 'Returns one issue in full: description, custom fields, all comments and ' \
                  'attribute changes (the discussion thread), related issues, subtasks and attachments.'
      input_schema(
        {
          type: 'object',
          properties: {
            id: {type: 'integer', description: 'Issue id (the number in the issue URL)'},
            include_journals: {
              type: 'boolean',
              description: 'Include comments and change history. Default: true. ' \
                           'Set to false for a shorter response when only the description matters.'
            }
          },
          required: ['id']
        }
      )

      DETAIL_VALUE_CLASSES = {
        'status_id' => proc {|v| IssueStatus.find_by_id(v)&.name},
        'tracker_id' => proc {|v| Tracker.find_by_id(v)&.name},
        'priority_id' => proc {|v| IssuePriority.find_by_id(v)&.name},
        'assigned_to_id' => proc {|v| Principal.find_by_id(v)&.name},
        'author_id' => proc {|v| Principal.find_by_id(v)&.name},
        'category_id' => proc {|v| IssueCategory.find_by_id(v)&.name},
        'fixed_version_id' => proc {|v| Version.find_by_id(v)&.name},
        'project_id' => proc {|v| Project.find_by_id(v)&.identifier},
        'parent_id' => proc {|v| "##{v}"}
      }.freeze

      def call(args)
        issue = find_issue!(args['id'])

        hash = issue_summary(issue)
        hash[:description] = issue.description
        hash[:category] = issue.category&.name
        hash[:target_version] = issue.fixed_version&.name
        hash[:is_private] = issue.is_private?
        hash[:done_ratio] = issue.done_ratio
        hash[:start_date] = issue.start_date&.iso8601
        hash[:due_date] = issue.due_date&.iso8601
        hash[:custom_fields] = issue.visible_custom_field_values(user).map do |value|
          {name: value.custom_field.name, value: value.value}
        end
        hash[:parent] = related_issue_hash(issue.parent) if issue.parent&.visible?(user)
        hash[:subtasks] = issue.children.visible(user).map {|child| related_issue_hash(child)}
        hash[:related_issues] = relations(issue)
        hash[:attachments] = issue.attachments.map {|attachment| attachment_hash(attachment)}
        hash[:journals] = journals(issue) unless args['include_journals'] == false
        hash.compact
      end

      private

      def related_issue_hash(other)
        {id: other.id, subject: other.subject, status: other.status.name}
      end

      def relations(issue)
        issue.relations.filter_map do |relation|
          other = relation.other_issue(issue)
          next unless other.visible?(user)

          related_issue_hash(other).merge(relation_type: relation.relation_type_for(issue))
        end
      end

      def attachment_hash(attachment)
        {
          id: attachment.id,
          filename: attachment.filename,
          filesize: attachment.filesize,
          content_type: attachment.content_type,
          author: attachment.author&.name,
          created_on: attachment.created_on&.iso8601,
          description: attachment.description.presence,
          url: base_url("/attachments/download/#{attachment.id}/#{ERB::Util.url_encode(attachment.filename)}")
        }.compact
      end

      def journals(issue)
        can_view_private = user.allowed_to?(:view_private_notes, issue.project)
        issue.journals.preload(:user, :details).order(:created_on, :id).filter_map do |journal|
          # Same as the web UI: private notes are omitted entirely unless the
          # user wrote them or may view private notes
          notes_visible = !journal.private_notes? || journal.user_id == user.id || can_view_private
          details = journal.visible_details(user).map {|detail| detail_hash(detail)}
          next if (!notes_visible || journal.notes.blank?) && details.empty?

          {
            id: journal.id,
            user: journal.user&.name,
            created_on: journal.created_on&.iso8601,
            private_notes: journal.private_notes?,
            notes: notes_visible ? journal.notes.presence : nil,
            details: details.presence
          }.compact
        end
      end

      def detail_hash(detail)
        case detail.property
        when 'attr'
          {
            attribute: detail.prop_key.sub(/_id\z/, ''),
            old_value: detail_value(detail.prop_key, detail.old_value),
            new_value: detail_value(detail.prop_key, detail.value)
          }
        when 'cf'
          {
            attribute: CustomField.find_by_id(detail.prop_key)&.name || "cf_#{detail.prop_key}",
            old_value: detail.old_value,
            new_value: detail.value
          }
        when 'attachment'
          {attribute: 'attachment', old_value: detail.old_value, new_value: detail.value}
        when 'relation'
          {attribute: "relation (#{detail.prop_key})", old_value: detail.old_value, new_value: detail.value}
        else
          {attribute: detail.prop_key, old_value: detail.old_value, new_value: detail.value}
        end.compact
      end

      def detail_value(prop_key, value)
        return nil if value.blank?

        if (resolver = DETAIL_VALUE_CLASSES[prop_key])
          resolver.call(value) || value
        else
          value
        end
      end
    end
  end
end
