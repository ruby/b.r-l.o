# This class hooks into Redmine's View Listeners in order to add content to the page
class RedmineS3Hooks < Redmine::Hook::ViewListener

  def view_layouts_base_html_head(context = {})
    javascript_include_tag 'redmine_s3.js', :plugin => 'redmine_s3'
  end
end
