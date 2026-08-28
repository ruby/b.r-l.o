# frozen_string_literal: true

module RedmineMcp
  module Tools
    class UnlinkIssues < Base
      tool_name 'unlink_issues'
      description 'Removes a relation between two issues. Name the relation either by issue_id and ' \
                  'target_issue_id, or by relation_id, which get_issue reports for every entry of ' \
                  'related_issues. Requires the manage_issue_relations permission in the project of ' \
                  'either issue. Subtasks are not relations and are not removed by this tool.'
      input_schema(
        {
          type: 'object',
          properties: {
            issue_id: {type: 'integer', description: 'One side of the relation'},
            target_issue_id: {type: 'integer', description: 'The other side of the relation'},
            relation_id: {
              type: 'integer',
              description: 'Relation to remove, from the related_issues of get_issue. ' \
                           'Replaces issue_id and target_issue_id.'
            }
          }
        }
      )

      def call(args)
        relation, issue = find_relation!(args)
        unless relation.deletable?(user)
          fail!("You are not allowed to manage the relations of issue ##{issue.id}")
        end

        relation.init_journals(user)
        relation.destroy
        {unlinked: true}.merge(relation_summary(relation, issue))
      end

      private

      def find_relation!(args)
        return by_relation_id(args['relation_id']) if args['relation_id'].present?
        if args['issue_id'].blank? && args['target_issue_id'].blank?
          fail!('Provide relation_id, or issue_id and target_issue_id')
        end

        by_issue_pair(args)
      end

      def by_relation_id(id)
        relation = IssueRelation.find_by_id(id.to_i)
        fail!("Issue relation ##{id} not found or not visible to you") unless relation&.visible?(user)

        [relation, relation.issue_from]
      end

      # Redmine stores at most one relation per ordered pair of issues, but the
      # reverse direction can hold another one, so the pair alone can be
      # ambiguous and the caller has to fall back to relation_id.
      def by_issue_pair(args)
        issue = find_issue!(args['issue_id'], field: 'issue_id')
        target = find_issue!(args['target_issue_id'], field: 'target_issue_id')
        relations = relations_between(issue, target)

        case relations.size
        when 0
          fail!("Issues ##{issue.id} and ##{target.id} are not linked. " \
                "Use get_issue on ##{issue.id} to see its current relations.")
        when 1
          [relations.first, issue]
        else
          listed = relations.map {|r| "#{r.id} (#{r.relation_type_for(issue)})"}.join(', ')
          fail!("Issues ##{issue.id} and ##{target.id} have several relations: #{listed}. " \
                'Pass relation_id to choose one.')
        end
      end
    end
  end
end
