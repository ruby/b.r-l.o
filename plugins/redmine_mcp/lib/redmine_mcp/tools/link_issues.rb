# frozen_string_literal: true

module RedmineMcp
  module Tools
    class LinkIssues < Base
      tool_name 'link_issues'
      description 'Links two issues with a relation, the same way the "Related issues" section of ' \
                  'the issue page does. Requires the manage_issue_relations permission in the project ' \
                  'of issue_id. Read the current links with get_issue (field related_issues) first: ' \
                  'a pair of issues normally holds one relation, which unlink_issues removes.'
      input_schema(
        {
          type: 'object',
          properties: {
            issue_id: {type: 'integer', description: 'Issue the relation is stated from, e.g. a tracking issue'},
            target_issue_id: {type: 'integer', description: 'Issue to link to'},
            relation_type: {
              type: 'string',
              enum: IssueRelation::TYPES.keys,
              description: 'How issue_id relates to target_issue_id. Default: relates. ' \
                           "'blocks'/'blocked' and 'precedes'/'follows' are the two directions of " \
                           'the same relation, as are duplicates/duplicated and copied_to/copied_from.'
            },
            delay: {
              type: 'integer',
              description: 'Days between the two issues, for precedes and follows only. Default: 0'
            }
          },
          required: %w[issue_id target_issue_id]
        }
      )

      DELAY_TYPES = [IssueRelation::TYPE_PRECEDES, IssueRelation::TYPE_FOLLOWS].freeze

      def call(args)
        issue = find_issue!(args['issue_id'], field: 'issue_id')
        target = find_issue!(args['target_issue_id'], field: 'target_issue_id')
        relation_type = relation_type!(args['relation_type'])

        fail!("Cannot link issue ##{issue.id} to itself") if issue.id == target.id
        unless user.allowed_to?(:manage_issue_relations, issue.project)
          fail!("You are not allowed to manage the relations of issue ##{issue.id}")
        end
        if args['delay'].present? && !DELAY_TYPES.include?(relation_type)
          fail!("delay only applies to the #{DELAY_TYPES.join(' and ')} relation types, not #{relation_type}")
        end

        relation = IssueRelation.new(issue_from: issue, issue_to: target, relation_type: relation_type)
        relation.delay = args['delay'] if args['delay'].present?
        relation.init_journals(user)

        saved =
          begin
            relation.save
          rescue ActiveRecord::RecordNotUnique
            # lost the race with a concurrent create, which validation misses
            relation.errors.add(:base, :taken)
            false
          end
        fail!(link_error(issue, target, relation)) unless saved

        {linked: true}.merge(relation_summary(relation, issue))
      end

      private

      def relation_type!(value)
        return IssueRelation::TYPE_RELATES if value.blank?

        relation_type = value.to_s.strip.downcase
        return relation_type if IssueRelation::TYPES.key?(relation_type)

        fail!("Unknown relation_type: #{value}. Available: #{IssueRelation::TYPES.keys.join(', ')}")
      end

      # A pair of issues that is already linked fails validation in ways that
      # do not name the existing relation, so report that instead
      def link_error(issue, target, relation)
        existing = relations_between(issue, target).first
        if existing
          "Issues ##{issue.id} and ##{target.id} are already linked as '#{existing.relation_type_for(issue)}'. " \
            'Remove that relation with unlink_issues before linking them differently.'
        else
          "Could not link ##{issue.id} to ##{target.id}: #{relation.errors.full_messages.join(', ')}"
        end
      end
    end
  end
end
