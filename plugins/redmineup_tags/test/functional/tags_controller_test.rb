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

class TagsControllerTest < ActionController::TestCase
  fixtures :projects,
           :users,
           :roles,
           :members,
           :member_roles,
           :issues,
           :issue_statuses,
           :versions,
           :trackers,
           :projects_trackers,
           :issue_categories,
           :enabled_modules,
           :enumerations,
           :attachments,
           :workflows,
           :custom_fields,
           :custom_values,
           :custom_fields_projects,
           :custom_fields_trackers

  def setup
    # run as the admin
    @request.session[:user_id] = 1

    @project_a = Project.generate!
    @project_b = Project.generate!

    add_issue @project_a, %w[a1 a2], false
    add_issue @project_a, %w[a2 a3], false
    add_issue @project_a, %w[a4 a5], true
    add_issue @project_b, %w[b6 b7], true
    add_issue @project_b, %w[b8 b9], false
  end

  def test_should_get_edit
    tag = RedmineCrm::Tag.find_by_name('a1')
    compatible_request :get, :edit, id: tag.id
    assert_response :success
    assert_select "input#tag_name[value='#{tag.name}']", 1
  end

  def test_should_put_update
    tag1 = RedmineCrm::Tag.find_by_name('a1')
    new_name = 'updated main'
    compatible_request :put, :update, id: tag1.id, tag: { name: new_name }
    assert_redirected_to controller: 'settings', action: 'plugin', id: 'redmineup_tags', tab: 'manage_tags'
    tag1.reload
    assert_equal new_name, tag1.name
  end

  test 'should delete destroy' do
    tag1 = RedmineCrm::Tag.find_by_name('a1')
    assert_difference 'RedmineCrm::Tag.count', -1 do
      compatible_request :post, :destroy, ids: tag1.id
      assert_response 302
    end
  end

  test 'should post merge' do
    tag1 = RedmineCrm::Tag.find_by_name('a1')
    tag2 = RedmineCrm::Tag.find_by_name('b8')
    assert_difference 'RedmineCrm::Tag.count', -1 do
      compatible_request :post, :merge, ids: [tag1.id, tag2.id], tag: { name: 'a1' }
      assert_redirected_to controller: 'settings', action: 'plugin', id: 'redmineup_tags', tab: 'manage_tags'
    end
    assert_equal 0, Issue.tagged_with('b8').count
    assert_equal 2, Issue.tagged_with('a1').count
  end

  private

  def add_issue(project, tags, closed)
    issue = Issue.generate!(project_id: project.id)
    issue.tag_list = tags
    issue.status = IssueStatus.where(is_closed: true).first if closed
    issue.save
  end
end
