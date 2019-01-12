require Rails.root.join('app', 'helpers', 'application_helper')

module RedmineLinkToRoot
  include ApplicationHelper
  extend ActiveSupport::Concern

  included do
    alias_method_chain :page_header_title, :root_link
  end

  def page_header_title_with_root_link
    if @project.nil? || @project.new_record?
      link_to(Setting.app_title, home_path)
    else
      page_header_title_without_root_link
    end
  end
end

ActionView::Base.send(:include, RedmineLinkToRoot)
