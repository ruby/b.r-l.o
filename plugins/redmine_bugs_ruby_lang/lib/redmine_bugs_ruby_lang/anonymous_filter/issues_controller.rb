# frozen_string_literal: true

module RedmineBugsRubyLang
  module AnonymousFilter
    module IssuesControllerPatch
      private

      def reject_anonymous_issue_filter
        return if User.current.logged?
        render_403 if excessive_query_params?
      end

      def excessive_query_params?
        params[:set_filter].present? ||
          params[:query_id].present? ||
          params[:sort].present? ||
          params[:per_page].to_i > 50 ||
          params[:page].to_i > 30
      end
    end
  end
end

IssuesController.class_eval do
  prepend RedmineBugsRubyLang::AnonymousFilter::IssuesControllerPatch

  caches_action :index,
    :if => -> { !User.current.logged? && !excessive_query_params? },
    :expires_in => 5.minutes,
    :cache_path => -> { request.GET.merge(locale: I18n.locale) }

  before_action :reject_anonymous_issue_filter, :only => :index
end
