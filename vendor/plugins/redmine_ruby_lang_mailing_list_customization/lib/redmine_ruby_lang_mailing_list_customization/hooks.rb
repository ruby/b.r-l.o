# -*- coding: UTF-8 -*-
module RedmineRubyLangMailingListCustomization
  class Hooks < Redmine::Hook::ViewListener
    def view_issues_form_details_top(context = {})
      issue, form = context[:issue], context[:form]
      return unless issue.new_record?

      options = [
        ["ruby-core in English", 'en'],
        ["ruby-dev in Japanese (日本語)", 'ja'],
      ]

      selected = [current_language.to_s, Setting.default_language].find{|lang| %w[ en ja ].include?(lang) }
      return "<p>%s</p>" % form.select(:lang, options, :required => true, :selected => selected, :label => l(:field_mailing_list))
    end

    def controller_issues_new_before_save(context = {})
      params, issue = context[:params], context[:issue]
      issue.lang = params[:issue][:lang] if params[:issue]
    end
  end
end
