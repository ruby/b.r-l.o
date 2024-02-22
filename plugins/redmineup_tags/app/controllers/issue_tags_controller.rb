# This file is a part of Redmine Tags (redmine_tags) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2021 RedmineUP
# http://www.redmineup.com/
#
# redmine_tags is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# redmine_tags is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with redmine_tags.  If not, see <http://www.gnu.org/licenses/>.

class IssueTagsController < ApplicationController
  unloadable

  before_action :find_issues, only: [:edit, :update]

  def edit
    return unless User.current.allowed_to?(:edit_tags, @projects.first)
    @issue_ids = params[:ids]
    @is_bulk_editing = @issue_ids.size > 1
    @most_used_tags = Issue.all_tags(sort_by: 'count', order: 'DESC').limit(10)
  end

  def update
    if User.current.allowed_to?(:edit_tags, @projects.first)
      tags = params[:issue] && params[:issue][:tag_list] ? params[:issue][:tag_list].reject(&:empty?) : []

      unless User.current.allowed_to?(:create_tags, @projects.first) || Issue.allowed_tags?(tags)
        flash[:error] = t(:notice_failed_to_add_tags)
        return
      end

      if update_tags(@issues, tags)
        flash[:notice] = t(:notice_tags_added)
      else
        flash[:error] = t(:notice_failed_to_add_tags)
      end
    else
      flash[:error] = t(:notice_failed_to_add_tags)
    end
  rescue Exception => e
    puts e
    flash[:error] = t(:notice_failed_to_add_tags)
  ensure
    redirect_to_referer_or { render text: 'Tags updated.', layout: true }
  end

  private

  def update_tags(issues, tags)
    if tags.present? && issues.size > 1
      add_issues_tags(issues, tags)
    else
      update_issues_tags(issues, tags)
    end
  end

  def add_issues_tags(issues, tags)
    saved = true
    Issue.transaction do
      issues.each do |issue|
        issue.tag_list = (issue.tag_list + tags).uniq
        saved &&= issue.save
        raise ActiveRecord::Rollback unless saved
      end
    end
    saved
  end

  def update_issues_tags(issues, tags)
    saved = true
    Issue.transaction do
      issues.each do |issue|
        issue.tag_list = tags
        saved &&= issue.save
        raise ActiveRecord::Rollback unless saved
      end
    end
    saved
  end
end
