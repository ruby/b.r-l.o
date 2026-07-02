# frozen_string_literal: true

module RedmineMcp
  module Tools
    class ListProjects < Base
      tool_name 'list_projects'
      description 'Lists the projects visible to you. Use the returned `identifier` ' \
                  'as the `project` argument of the other tools.'
      input_schema(
        {
          type: 'object',
          properties: {
            include_closed: {
              type: 'boolean',
              description: 'Also list closed (read-only) projects. Default: false'
            },
            limit: {type: 'integer', description: 'Maximum number of results (default 25, max 100)'},
            offset: {type: 'integer', description: 'Number of results to skip, for pagination'}
          },
          required: []
        }
      )

      def call(args)
        limit, offset = pagination(args)
        scope = Project.visible(user).sorted
        scope = scope.active unless args['include_closed']

        {
          total_count: scope.count,
          offset: offset,
          limit: limit,
          projects: scope.offset(offset).limit(limit).map {|project| project_hash(project)}
        }
      end

      private

      def project_hash(project)
        {
          identifier: project.identifier,
          name: project.name,
          description: project.description.to_s.truncate(200),
          parent: project.parent&.identifier,
          closed: !project.active?,
          url: base_url("/projects/#{project.identifier}")
        }.compact
      end
    end
  end
end
