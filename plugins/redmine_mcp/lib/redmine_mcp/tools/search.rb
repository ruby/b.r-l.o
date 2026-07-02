# frozen_string_literal: true

module RedmineMcp
  module Tools
    class Search < Base
      tool_name 'search'
      description 'Full-text search across issues (subject, description, notes), wiki pages ' \
                  'and other content, like the search box in the web UI. ' \
                  'Returns brief matches; use get_issue or get_wiki_page for the full content. ' \
                  'For structured filtering (by status, assignee, dates...) use list_issues instead.'
      input_schema(
        {
          type: 'object',
          properties: {
            q: {type: 'string', description: 'Words to search for. All words must match.'},
            project: {type: 'string', description: 'Restrict the search to this project identifier'},
            types: {
              type: 'array',
              items: {type: 'string'},
              description: "Content types to search. Available: issues, wiki_pages, news, documents, " \
                           "changesets, messages, projects. Default: ['issues', 'wiki_pages']"
            },
            titles_only: {type: 'boolean', description: 'Search titles/subjects only. Default: false'},
            open_issues: {type: 'boolean', description: 'Match open issues only. Default: false'},
            limit: {type: 'integer', description: 'Maximum number of results (default 25, max 100)'},
            offset: {type: 'integer', description: 'Number of results to skip, for pagination'}
          },
          required: ['q']
        }
      )

      DEFAULT_TYPES = %w[issues wiki_pages].freeze

      def call(args)
        question = args['q'].to_s.strip
        fail!('Missing required argument: q') if question.blank?

        limit, offset = pagination(args)
        types = Array(args['types']).map(&:to_s)
        types = DEFAULT_TYPES.dup if types.empty?
        unknown = types - Redmine::Search.available_search_types
        fail!("Unknown types: #{unknown.join(', ')}. Available: #{Redmine::Search.available_search_types.join(', ')}") if unknown.any?

        projects = args['project'].present? ? [find_project!(args['project'])] : nil
        fetcher = Redmine::Search::Fetcher.new(
          question, user, types, projects,
          all_words: true,
          titles_only: !!args['titles_only'],
          attachments: '0',
          open_issues: !!args['open_issues'],
          cache: false
        )

        {
          query: question,
          total_count: fetcher.result_count,
          offset: offset,
          limit: limit,
          results: fetcher.results(offset, limit).map {|record| result_hash(record)}
        }
      end

      private

      def result_hash(record)
        {
          type: record.class.name.underscore,
          title: record.event_title,
          datetime: record.event_datetime&.iso8601,
          description: record.event_description.to_s.truncate(300),
          issue_id: record.is_a?(Issue) ? record.id : nil,
          url: event_url(record)
        }.compact
      end

      def event_url(record)
        base_url(Rails.application.routes.url_for(record.event_url.merge(only_path: true)))
      rescue StandardError
        nil
      end
    end
  end
end
