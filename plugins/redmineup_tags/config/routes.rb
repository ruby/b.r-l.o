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

RedmineApp::Application.routes.draw do
  match '/issue_tags/auto_complete/:project_id', to: 'auto_completes#issue_tags', via: :get, as: 'auto_complete_issue_tags'
  match '/wiki_tags/auto_complete/:project_id', to: 'auto_completes#wiki_tags', via: :get, as: 'auto_complete_wiki_tags'
  match 'auto_completes/redmine_tags' => 'auto_completes#redmine_tags', via: :get, as: 'auto_complete_redmine_tags'
  match '/tags/context_menu', to: 'tags#context_menu', as: 'tags_context_menu', via: [:get, :post]
  match '/tags', controller: 'tags', action: 'destroy', via: :delete
end

resources :tags, only: [:edit, :update] do
  collection do
    post :merge
    get :context_menu, :merge
  end
end

get :edit_issue_tags, to: 'issue_tags#edit'
post :update_issue_tags, to: 'issue_tags#update'
