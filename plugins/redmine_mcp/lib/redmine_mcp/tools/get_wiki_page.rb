# frozen_string_literal: true

module RedmineMcp
  module Tools
    class GetWikiPage < Base
      tool_name 'get_wiki_page'
      description 'Returns a wiki page of a project (the start page when no title is given), ' \
                  'or the list of all page titles when list is true. ' \
                  'ruby/ruby development guidelines such as DevelopersMeeting or HowToContribute live in the wiki.'
      input_schema(
        {
          type: 'object',
          properties: {
            project: {type: 'string', description: 'Project identifier (see list_projects)'},
            title: {type: 'string', description: 'Page title. Default: the wiki start page'},
            list: {type: 'boolean', description: 'Return the titles of all pages instead of one page. Default: false'}
          },
          required: ['project']
        }
      )

      def call(args)
        project = find_project!(args['project'])
        fail!("You are not allowed to view the wiki of #{project.identifier}") unless user.allowed_to?(:view_wiki_pages, project)

        wiki = project.wiki
        fail!("Project #{project.identifier} has no wiki") unless wiki

        return page_list(project, wiki) if args['list']

        title = args['title'].presence || wiki.start_page
        page = wiki.find_page(title)
        unless page&.content && page.visible?(user)
          fail!("Wiki page not found: #{title}. Use list: true to see available pages.")
        end

        {
          project: project.identifier,
          title: page.title,
          version: page.content.version,
          author: page.content.author&.name,
          updated_on: page.content.updated_on&.iso8601,
          text_formatting: Setting.text_formatting,
          text: page.content.text,
          url: page_url(project, page.title)
        }
      end

      private

      def page_list(project, wiki)
        {
          project: project.identifier,
          start_page: wiki.start_page,
          pages: wiki.pages.order(:title).pluck(:title)
        }
      end

      def page_url(project, title)
        base_url("/projects/#{project.identifier}/wiki/#{ERB::Util.url_encode(title)}")
      end
    end
  end
end
