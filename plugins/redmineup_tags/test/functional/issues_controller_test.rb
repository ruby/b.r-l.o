# encoding: utf-8
#
# This file is a part of Redmine Tags (redmine_tags) plugin,
# customer relationship management plugin for Redmine
#
# Copyright (C) 2011-2019 RedmineUP
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

class IssuesControllerTest < ActionController::TestCase
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
    @tag = RedmineCrm::Tag.create(name: 'test_tag')
    @last_tag = RedmineCrm::Tag.create(name: 'last_tag')
    @request.session[:user_id] = 1
  end

  def test_get_index_with_tags
    issue = Issue.find(2)
    issue.tags << @tag
    compatible_request(
      :get,
      :index,
      f: ['status_id', 'issue_tags', ''],
      op: { status_id: 'o', issue_tags: '=' },
      v: { issue_tags: ['test_tag'] },
      c: ['status', 'priority', 'subject', 'tags_relations'],
      project_id: 'ecookbook'
    )
    assert_response :success
    assert_select 'table.list.issues tr.issue', 1
    assert_select 'table.list.issues tr.issue td.subject', issue.subject
    assert_select 'table.list.issues tr.issue td.tags a', 'test_tag'
  ensure
    issue.tags = []
  end

  def test_get_index_with_sidebar_tags_in_list_by_count
    issue1 = Issue.find(1)
    issue1.tags << @tag
    issue2 = Issue.find(2)
    issue2.tags << @tag
    issue2.tags << @last_tag
    RedmineupTags.stubs(:settings).returns('issues_sidebar' => 'list',
                                           'issues_show_count' => '1',
                                           'issues_sort_by' => 'count',
                                           'issues_sort_order' => 'desc')

    compatible_request :get, :index, project_id: 'ecookbook'
    assert_response :success
    assert_select '.tag-label', 'test_tag(2)'
  ensure
    issue1.tags = []
    issue2.tags = []
    RedmineupTags.unstub(:settings)
  end

  def test_get_index_with_sidebar_tags_in_cloud_by_count
    issue1 = Issue.find(1)
    issue1.tags << @last_tag

    issue2 = Issue.find(2)
    issue2.tags << @tag
    issue2.tags << @last_tag

    RedmineupTags.stubs(:settings).returns('issues_sidebar' => 'cloud',
                                           'issues_show_count' => '1',
                                           'issues_sort_by' => 'count',
                                           'issues_sort_order' => 'desc')
    compatible_request :get, :index, project_id: 'ecookbook'
    assert_response :success
    assert_select '.tag-label', 'last_tag(2)'
  ensure
    issue1.tags = []
    issue2.tags = []
    RedmineupTags.unstub(:settings)
  end

  def test_should_not_update_without_tag_list
    tags = %w[second third]
    assert_equal tags, Issue.find(1).tag_list.sort
    compatible_request :post, :update, id: 1, issue: { project_id: 1 }
    assert_response :redirect
    assert_equal tags, Issue.find(1).tag_list.sort
  end

  def test_should_update_with_empty_string_tags
    assert_equal %w[second third], Issue.find(1).tag_list.sort
    compatible_request :post, :update, id: 1, issue: { project_id: 1, tag_list: ['', ''] }
    assert_response :redirect
    assert_equal [], Issue.find(1).tag_list
  end

  def test_should_update_with_new_tags
    assert_equal %w[second third], Issue.find(1).tag_list.sort
    compatible_request :post, :update, id: 1, issue: { project_id: 1, tag_list: %w[new_tag1 new_tag2] }
    assert_response :redirect
    assert_equal %w[new_tag1 new_tag2], Issue.find(1).tag_list.sort
  end

  def test_should_update_issue_and_tags
    assert_equal %w[second third], Issue.find(1).tag_list.sort
    compatible_request :post, :update, id: 1, issue: {
      project_id: 1,
      description: 'Test should update issue and tags',
      tag_list: %w[new_tag1 new_tag2]
    }
    assert_response :redirect
    issue = Issue.find(1)
    assert_equal 'Test should update issue and tags', issue.description
    assert_equal %w[new_tag1 new_tag2], issue.tag_list.sort
  end

  def test_get_bulk_edit_with_tags
    compatible_request :get, :bulk_edit, ids: [1, 2]
    assert_select '#issue_tags'
    assert_response :success
  end

  def test_post_bulk_edit_without_tag_list
    issue1 = Issue.find(1)
    issue1.tags = [@tag]

    issue2 = Issue.find(2)
    issue2.tags = [@last_tag]

    compatible_request :post, :bulk_update, ids: [1, 2], issue: { project_id: '', tracker_id: '' }
    assert_response :redirect
    assert_equal [@tag.name], Issue.find(1).tag_list
    assert_equal [@last_tag.name], Issue.find(2).tag_list
  ensure
    issue1.tags = []
    issue2.tags = []
    RedmineupTags.unstub(:settings)
  end

  def test_post_bulk_edit_with_empty_string_tags
    (1..2).each { |i| assert_equal %w[second third], Issue.find(i).tag_list.sort }
    compatible_request :post, :bulk_update, ids: [1, 2], issue: { project_id: '', tracker_id: '', tag_list: ['', ''] }
    assert_response :redirect
    (1..2).each { |i| assert_equal [], Issue.find(i).tag_list }
  end

  def test_post_bulk_edit_with_changed_tags
    issue1 = Issue.find(1)
    issue1.tags << @tag

    issue2 = Issue.find(2)
    issue2.tags << @last_tag

    compatible_request :post, :bulk_update, ids: [1, 2], issue: { project_id: '', tracker_id: '', tag_list: ['bulk_tag'] }
    assert_response :redirect
    assert_equal ['bulk_tag'], Issue.find(1).tag_list
    assert_equal ['bulk_tag'], Issue.find(2).tag_list
  ensure
    issue1.tags = []
    issue2.tags = []
    RedmineupTags.unstub(:settings)
  end

  def test_get_new_with_permission_edit_tags
    # User(id: 2) has role Manager in Project(id: 1)
    @request.session[:user_id] = 2
    manager_role = Role.find(1)
    manager_role.add_permission! :edit_tags
    compatible_request :get, :new, issue: { project_id: 1 }
    assert_select '#issue_tags'
  end

  def test_get_new_without_permission_edit_tags
    @request.session[:user_id] = 2
    manager_role = Role.find(1)
    manager_role.remove_permission! :edit_tags
    compatible_request :get, :new, issue: { project_id: 1 }
    assert_select '#issue_tags', 0
  end

  def test_get_new_with_permission_edit_tags_in_other_project
    # User(id: 2) has role Manager in Project(id: 1) and role Developer in Project(id: 2)
    @request.session[:user_id] = 2
    manager_role = Role.find(1)
    manager_role.add_permission! :edit_tags
    compatible_request :get, :new, issue: { project_id: 2 }
    assert_select '#issue_tags', 0
  end

  def test_get_edit_with_permission_edit_tags
    # User(id: 2) has role Manager in Project(id: 1) and Project(id: 1) contains Issue(id: 1)
    @request.session[:user_id] = 2
    manager_role = Role.find(1)
    manager_role.add_permission! :edit_tags
    compatible_request :get, :edit, id: 1, issue: { project_id: 1 }
    assert_select '#issue_tags'
  end

  def test_get_edit_without_permission_edit_tags
    @request.session[:user_id] = 2
    manager_role = Role.find(1)
    manager_role.remove_permission! :edit_tags
    compatible_request :get, :edit, id: 1, issue: { project_id: 1 }
    assert_select '#issue_tags', 0
  end

  def test_get_edit_with_permission_edit_tags_in_other_project
    # User(id: 2) has role Manager in Project(id: 1) and role Developer in Project(id: 2)
    # Project(id: 1) contains Issue(id: 1)
    @request.session[:user_id] = 2
    manager_role = Role.find(1)
    manager_role.add_permission! :edit_tags
    compatible_request :get, :edit, id: 1, issue: { project_id: 2 }
    assert_select '#issue_tags', 0
  end
  
  def test_edit_tags_permission
    # User(id: 2) has role Manager in Project(id: 1) and Project(id: 1) contains Issue(id: 1)
    @request.session[:user_id] = 2
    manager_role = Role.find(1)
    manager_role.add_permission! :edit_tags
    tag = 'first'

    assert_not_equal Issue.find(1).tag_list, [tag]
    assert Issue.all_tags.map(&:name).include?(tag)
    compatible_request :post, :update, id: 1, issue: { project_id: 1, tag_list: [tag] }
    assert_response :redirect
    assert_equal Issue.find(1).tag_list, [tag]

    manager_role.remove_permission! :edit_tags
    tag2 = 'second'

    assert Issue.all_tags.map(&:name).include?(tag2)
    assert_equal Issue.find(1).description, 'Unable to print recipes'
    compatible_request :post, :update, id: 1, issue: { project_id: 1, description: 'New description', tag_list: [tag2] }
    assert_response :redirect
    issue = Issue.find(1)
    assert_equal 'New description', issue.description
    assert_equal [tag], issue.tag_list
  end

  def test_create_tags_permission
    @request.session[:user_id] = 2
    manager_role = Role.find(1)
    manager_role.add_permission! :edit_tags, :create_tags
    new_tag = 'enable_create_tags_permission'

    assert_not_equal Issue.find(1).tag_list, [new_tag]
    assert !Issue.all_tags.map(&:name).include?(new_tag) # The project should not contain the new tag
    compatible_request :post, :update, id: 1, issue: { project_id: 1, tag_list: [new_tag] }
    assert_response :redirect
    assert_equal [new_tag], Issue.find(1).tag_list

    manager_role.remove_permission! :create_tags
    new_tag2 = 'disable_create_tags_permission'

    assert !Issue.all_tags.map(&:name).include?(new_tag2)
    compatible_request :post, :update, id: 1, issue: { project_id: 1, tag_list: [new_tag2] }
    assert_response :redirect
    assert_equal Issue.find(1).tag_list, [new_tag]
  end

  def test_filter_by_tags_equal
    tags = %w(first second)
    compatible_request :get, :index, project_id: 1, set_filter: 1, f: ['issue_tags', ''], op: { issue_tags: '=' }, v: { issue_tags: tags }
    assert_response :success
    issues_in_list.each { |issue| assert_equal (tags & issue.tag_list), tags }
  end

  def test_filter_by_tags_not_equal
    tags = %w(first second)
    compatible_request :get, :index, project_id: 1, set_filter: 1, f: ['issue_tags', ''], op: { issue_tags: '!' }, v: { issue_tags: tags }
    assert_response :success
    issues_in_list.each { |issue| assert_not_equal (tags & issue.tag_list), tags }
  end
end
