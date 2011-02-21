module RedmineMailingListIntegration
  class Hooks < Redmine::Hook::ViewListener
    def view_issues_show_details_bottom(context = {})
      message = context[:issue].mailing_list_message
      if message
        if message.archive_url
          '<a href="%2$s">%1$s</a>' % [ message.identifier, message.archive_url ]
        else
          h(message.identifier)
        end
      end
    end

    def view_layouts_base_html_head(context = {})
      stylesheet_link_tag "mailing_list_integration", :plugin => "redmine_mailing_list_integration", :media => "screen"
    end

    def controller_issues_new_before_save(context = {})
      issue = context[:issue]
      issue.originates_from_mail = true
    end
  end
end
