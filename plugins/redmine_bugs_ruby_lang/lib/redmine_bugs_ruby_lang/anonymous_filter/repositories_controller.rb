# frozen_string_literal: true

module RedmineBugsRubyLang
  module AnonymousFilter
    module RepositoriesController
      GITHUB_COMMIT_URL = "https://github.com/ruby/ruby/commit/"

      private

      def redirect_anonymous_revision_to_github
        return if User.current.logged?
        return unless @project&.identifier == "ruby-master"

        redirect_to "#{GITHUB_COMMIT_URL}#{@changeset.revision}",
          :status => :moved_permanently, :allow_other_host => true
      end
    end
  end
end

RepositoriesController.class_eval do
  prepend RedmineBugsRubyLang::AnonymousFilter::RepositoriesController

  before_action :redirect_anonymous_revision_to_github, :only => :revision
end
