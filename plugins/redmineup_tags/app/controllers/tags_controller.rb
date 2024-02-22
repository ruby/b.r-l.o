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

class TagsController < ApplicationController
  unloadable
  before_action :require_admin
  before_action :find_tag, only: [:edit, :update]
  before_action :bulk_find_tags, only: [:context_menu, :merge, :destroy]

  helper :issues_tags

  def edit
  end

  def destroy
    @tags.each do |tag|
      begin
        tag.reload.destroy
      rescue ::ActiveRecord::RecordNotFound
      end
    end

    redirect_back_or_default(controller: 'settings', action: 'plugin', id: 'redmineup_tags', tab: 'manage_tags')
  end

  def update
    @tag.name = params[:tag][:name] if params[:tag]
    if @tag.save
      flash[:notice] = l(:notice_successful_update)
      respond_to do |format|
        format.html { redirect_to controller: 'settings', action: 'plugin', id: 'redmineup_tags', tab: 'manage_tags' }
        format.xml  {}
      end
    else
      respond_to do |format|
        format.html { render action: 'edit' }
      end
    end
  end

  def context_menu
    @tag = @tags.first if @tags.size == 1
    @back = back_url
    render layout: false
  end

  def merge
    if request.post? && params[:tag] && params[:tag][:name]
      RedmineCrm::Tagging.transaction do
        tag = RedmineCrm::Tag.find_by_name(params[:tag][:name]) || RedmineCrm::Tag.create(params[:tag])
        RedmineCrm::Tagging.where(tag_id: @tags.map(&:id)).update_all(tag_id: tag.id)
        @tags.select { |t| t.id != tag.id }.each{ |t| t.destroy }
        redirect_to controller: 'settings', action: 'plugin', id: 'redmineup_tags', tab: 'manage_tags'
      end
    end
  end

  private

  def bulk_find_tags
    @tags = RedmineCrm::Tag.joins("JOIN #{RedmineCrm::Tagging.table_name} ON #{RedmineCrm::Tagging.table_name}.tag_id = #{RedmineCrm::Tag.table_name}.id ").
            select("#{RedmineCrm::Tag.table_name}.*, COUNT(DISTINCT #{RedmineCrm::Tagging.table_name}.taggable_id) AS count").
            where(id: params[:id] ? [params[:id]] : params[:ids]).
            group("#{RedmineCrm::Tag.table_name}.id, #{RedmineCrm::Tag.table_name}.name")
    raise ActiveRecord::RecordNotFound if @tags.empty?
  end

  def find_tag
    @tag = RedmineCrm::Tag.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
