# frozen_string_literal: true

module RedmineBugsRubyLang
  module ArchivedPermalink
    module User
      # Redmine grants no role at all on an archived project, which would deny
      # the read that Project#allows_to? lets through. Actions stay gated there.
      def roles_for_project(project)
        return super unless project&.archived?

        if (membership = membership(project))
          membership.roles.to_a
        elsif project.is_public?
          project.override_roles(builtin_role)
        else
          []
        end
      end
    end
  end
end

User.class_eval do
  prepend RedmineBugsRubyLang::ArchivedPermalink::User
end
