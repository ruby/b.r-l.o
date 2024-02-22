# encoding: utf-8
#
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

require File.expand_path('../../test_helper', __FILE__)

class AgileVersionsControllerTest < ActionController::TestCase
  fixtures :projects,
           :users

  def setup
    @project_1 = Project.find(1)
    ['agile', 'agile_backlog'].each do |p_module|
      EnabledModule.create(project: @project_1, name: p_module)
    end

    @request.session[:user_id] = 1
  end

  def test_get_index_with_filters
    return unless Redmine::Plugin.installed?(:redmine_agile) && AGILE_VERSION_TYPE == 'PRO version'

    compatible_request :get, :index, project_id: @project_1.identifier
    assert_response :success
    assert response.body.match /issue_tags/
  end
end
