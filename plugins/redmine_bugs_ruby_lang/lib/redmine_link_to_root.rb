require Rails.root.join('app', 'helpers', 'application_helper')

module ActionViewPatch
  include ApplicationHelper
  extend ActiveSupport::Concern

  included do
    prepend RedmineLinkToRoot
  end

  module RedmineLinkToRoot
    def page_header_title
      if @project.nil? || @project.new_record?
        link_to(Setting.app_title, home_path)
      else
        super
      end
    end
  end
end

ActionView::Base.include ActionViewPatch
