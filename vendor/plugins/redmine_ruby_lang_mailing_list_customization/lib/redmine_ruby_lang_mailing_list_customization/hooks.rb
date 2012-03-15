# -*- coding: UTF-8 -*-
module RedmineRubyLangMailingListCustomization
  class Hooks < Redmine::Hook::ViewListener
    def view_issues_form_details_top(context = {})
      issue, form, project = context[:issue], context[:form], context[:project]
      return unless issue.new_record?
      return unless project and project.mailing_lists.any?{|ml| %w[ ruby-core ruby-dev ].include?(ml.identifier) }

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

    def model_changeset_scan_commit_for_issue_ids_pre_issue_update(context = {})
      issue = context[:issue]
      journal = issue.current_journal
      changeset = context[:changeset]

      journal.notes += "\n\n----------\n#{changeset.comments}"
    end
  end
end
