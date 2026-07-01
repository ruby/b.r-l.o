# frozen_string_literal: true

module RedmineBugsRubyLang
  module AnonymousFilter
    module ActivitiesController
      private

      def reject_anonymous_activity_filter
        return if User.current.logged?
        render_403 if excessive_activity_params?
      end

      def excessive_activity_params?
        params[:from].present? ||
          params[:user_id].present?
      end
    end
  end
end

ActivitiesController.class_eval do
  prepend RedmineBugsRubyLang::AnonymousFilter::ActivitiesController

  before_action :reject_anonymous_activity_filter, :only => :index
end
