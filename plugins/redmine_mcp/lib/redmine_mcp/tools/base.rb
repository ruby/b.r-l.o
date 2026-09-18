# frozen_string_literal: true

module RedmineMcp
  module Tools
    class Base
      class << self
        def tool_name(value = nil)
          @tool_name = value if value
          @tool_name
        end

        def description(value = nil)
          @description = value if value
          @description
        end

        def input_schema(value = nil)
          @input_schema = value if value
          @input_schema || {type: 'object', properties: {}}
        end

        def definition
          {name: tool_name, description: description, inputSchema: input_schema}
        end
      end

      attr_reader :user

      def initialize(user)
        @user = user
      end

      def call(args)
        raise NotImplementedError
      end

      private

      def fail!(message)
        raise ToolError, message
      end

      def base_url(path)
        "#{Setting.protocol}://#{Setting.host_name}#{path}"
      end

      def find_project!(identifier)
        fail!('Missing required argument: project') if identifier.blank?

        identifier = identifier.to_s
        scope = Project.visible(user)
        project = scope.find_by_identifier(identifier)
        project ||= scope.find_by_id(identifier.to_i) if /\A\d+\z/.match?(identifier)
        project || fail!("Project not found or not visible: #{identifier}")
      end

      def find_issue!(id, field: 'id')
        fail!("Missing required argument: #{field}") if id.blank?

        Issue.visible(user).find_by_id(id.to_i) ||
          fail!("Issue ##{id} not found or not visible to you")
      end

      def pagination(args, default: 25, max: 100)
        limit = args['limit'].to_i
        limit = default if limit <= 0
        limit = max if limit > max
        offset = [args['offset'].to_i, 0].max
        [limit, offset]
      end

      # Accepts a numeric id or a login and returns the matching active
      # principal (user or group)
      def resolve_principal!(value)
        value = value.to_s.strip
        principal =
          if /\A\d+\z/.match?(value)
            Principal.find_by_id(value.to_i)
          else
            User.active.find_by_login(value)
          end
        principal || fail!("User not found: #{value} (use a numeric id or a login)")
      end

      # With a project, restricts to that project's trackers; without one
      # (e.g. a global issue filter) resolves against all trackers.
      def resolve_tracker!(value, project: nil)
        value = value.to_s.strip
        trackers = project ? project.trackers : Tracker.sorted
        tracker =
          if /\A\d+\z/.match?(value)
            trackers.find_by_id(value.to_i)
          else
            trackers.detect {|t| t.name.casecmp?(value)}
          end
        tracker || fail!("Unknown tracker: #{value}. Available: #{trackers.map(&:name).join(', ')}")
      end

      def resolve_status!(value)
        value = value.to_s.strip
        status =
          if /\A\d+\z/.match?(value)
            IssueStatus.find_by_id(value.to_i)
          else
            IssueStatus.all.detect {|s| s.name.casecmp?(value)}
          end
        status || fail!("Unknown status: #{value}. Available: #{IssueStatus.sorted.pluck(:name).join(', ')}")
      end

      def resolve_priority!(value)
        value = value.to_s.strip
        priorities = IssuePriority.active
        priority =
          if /\A\d+\z/.match?(value)
            priorities.find_by_id(value.to_i)
          else
            priorities.detect {|p| p.name.casecmp?(value)}
          end
        priority || fail!("Unknown priority: #{value}. Available: #{priorities.map(&:name).join(', ')}")
      end

      def resolve_category!(project, value)
        value = value.to_s.strip
        categories = project.issue_categories
        category =
          if /\A\d+\z/.match?(value)
            categories.find_by_id(value.to_i)
          else
            categories.detect {|c| c.name.casecmp?(value)}
          end
        category || fail!("Unknown category: #{value}. Available: #{categories.map(&:name).join(', ')}")
      end

      def resolve_version!(project, value)
        value = value.to_s.strip
        versions = project.shared_versions
        version =
          if /\A\d+\z/.match?(value)
            versions.find_by_id(value.to_i)
          else
            versions.detect {|v| v.name.casecmp?(value)}
          end
        version || fail!("Unknown version: #{value}. Available: #{versions.map(&:name).join(', ')}")
      end

      def parse_time!(value, field)
        Time.zone.parse(value.to_s) || fail!("Invalid #{field}: #{value}")
      rescue ArgumentError
        fail!("Invalid #{field}: #{value} (use an ISO 8601 date or datetime)")
      end

      # Maps a {field name => value} hash to the {custom_field_id => value}
      # shape expected by safe_attributes 'custom_field_values'.
      def custom_field_values!(project, fields)
        available = project.all_issue_custom_fields
        fields.each_with_object({}) do |(name, value), values|
          field = available.detect {|f| f.name.casecmp?(name.to_s.strip)}
          field || fail!("Unknown custom field: #{name}. Available: #{available.map(&:name).join(', ')}")
          values[field.id.to_s] = value
        end
      end

      # Plugins extend issue writes through the hooks IssuesController fires
      # around a save, so the issue tools fire them too. Listeners read their
      # own form fields from params, and the tools have none to pass.
      def call_issue_hook(hook, issue, context = {})
        Redmine::Hook.call_hook(hook, {params: ActionController::Parameters.new, issue: issue, project: issue.project}.merge(context))
      end

      # Resolves a commit the way the repository page does, through the
      # per-adapter lookup that also accepts an abbreviated git SHA. The same
      # revision can exist in several repositories, so an ambiguous one is
      # reported rather than resolved to an arbitrary match.
      def find_changeset!(revision, project: nil, repository: nil)
        fail!('Missing required argument: revision') if revision.blank?

        revision = revision.to_s.strip
        repositories = visible_repositories(project, repository)
        changesets = repositories.filter_map {|repo| repo.find_changeset_by_name(revision)}.uniq
        case changesets.size
        when 1
          changesets.first
        when 0
          fail!("Revision #{revision} was not found in #{repository_scope_label(repositories, project, repository)}. " \
                'Redmine can only link a commit it has already fetched, so a commit pushed since the last fetch ' \
                'of the repository has to wait for the next one.')
        else
          listed = changesets.map {|c| "#{c.revision} (#{changeset_location(c)})"}.join(', ')
          fail!("Revision #{revision} matches several commits: #{listed}. " \
                'Pass project, or repository, to choose one.')
        end
      end

      def authorize_related_issues!(changeset)
        return if user.allowed_to?(:manage_related_issues, changeset.project)

        fail!("You are not allowed to manage the issues related to the commits of #{changeset.project.identifier}")
      end

      # already reports that the call found the link already in the state it
      # asks for, so that a retry is distinguishable from the write itself
      def changeset_link_summary(changeset, issue, already: false, verb: :linked)
        summary = {
          verb => true,
          :issue => {id: issue.id, subject: issue.subject},
          :changeset => {
            revision: changeset.revision,
            project: changeset.project.identifier,
            repository: changeset.repository.identifier.presence,
            user: changeset.user&.name,
            comments: changeset.comments.presence,
            committed_on: changeset.committed_on&.iso8601
          }.compact
        }
        summary[:"already_#{verb}"] = true if already
        summary
      end

      def relations_between(issue, other)
        issue.relations.select {|relation| relation.other_issue(issue).id == other.id}
      end

      # relation_type is reported from issue's point of view, the same way the
      # caller states it and get_issue reports it
      def relation_summary(relation, issue)
        other = relation.other_issue(issue)
        {
          relation_id: relation.id,
          relation_type: relation.relation_type_for(issue),
          delay: relation.delay,
          issue: {id: issue.id, subject: issue.subject},
          target_issue: {id: other.id, subject: other.subject}
        }.compact
      end

      # Commits are readable with :view_changesets, the same permission
      # get_issue reports them under; writing the link needs more and is
      # checked separately.
      def visible_repositories(project, identifier)
        scope = Repository.joins(:project).where(Project.allowed_to_condition(user, :view_changesets))
        scope = scope.where(project_id: find_project!(project).id) if project.present?
        repositories = scope.to_a
        return repositories if identifier.blank?

        repositories.select {|repo| repo.identifier.to_s.casecmp?(identifier.to_s.strip)}
      end

      def changeset_location(changeset)
        [changeset.project.identifier, changeset.repository.identifier.presence].compact.join(' / ')
      end

      def repository_scope_label(repositories, project, identifier)
        return "the #{identifier} repository of #{project}" if project.present? && identifier.present?
        return "the repositories of #{project}" if project.present?
        return "any repository named #{identifier}" if identifier.present?
        return 'any repository visible to you' if repositories.any?

        'any repository, because none is visible to you'
      end

      def issue_summary(issue)
        {
          id: issue.id,
          subject: issue.subject,
          project: issue.project.identifier,
          tracker: issue.tracker.name,
          status: issue.status.name,
          priority: issue.priority&.name,
          author: issue.author&.name,
          assigned_to: issue.assigned_to&.name,
          created_on: issue.created_on&.iso8601,
          updated_on: issue.updated_on&.iso8601,
          closed_on: issue.closed_on&.iso8601,
          url: base_url("/issues/#{issue.id}")
        }.compact
      end
    end
  end
end
