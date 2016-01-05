require Rails.root.join('app', 'helpers', 'application_helper')

module RedmineLinkToRoot
  include ApplicationHelper

  def page_header_title_root_link
    if @project.nil? || @project.new_record?
      link_to(Setting.app_title, home_path)
    else
      super
    end
  end
end

ActionView::Base.send(:prepend, RedmineLinkToRoot)
