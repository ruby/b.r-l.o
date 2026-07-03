# frozen_string_literal: true

module RedmineMcp
  module Tools
    class Whoami < Base
      tool_name 'whoami'
      description 'Returns the user account associated with the API key, ' \
                  'the wiki text formatting used for issue descriptions and notes, ' \
                  'and the projects the user is a member of. ' \
                  'Useful to verify authentication before doing anything else.'
      input_schema({type: 'object', properties: {}, required: []})

      def call(_args)
        {
          id: user.id,
          login: user.login,
          name: user.name,
          admin: user.admin?,
          text_formatting: Setting.text_formatting,
          site: base_url('/'),
          member_of: user.memberships.preload(:project).filter_map {|m| m.project&.identifier}.sort
        }
      end
    end
  end
end
