# frozen_string_literal: true

module RedmineBugsRubyLang
  module ArchivedPermalink
    module Project
      # Archived projects stay out of every SQL visibility scope, so nothing
      # links to their issues. Reading one by permalink is still allowed here.
      READABLE_ACTIONS = %w[issues/show issues/issue_tab].freeze

      def allows_to?(action)
        return super unless archived?

        if action.is_a?(Hash)
          name = "#{action[:controller]}/#{action[:action]}"
          READABLE_ACTIONS.include?(name) && allowed_actions.include?(name)
        else
          action == :view_issues && allowed_permissions.include?(action)
        end
      end
    end
  end
end

Project.class_eval do
  prepend RedmineBugsRubyLang::ArchivedPermalink::Project
end
