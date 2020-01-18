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

class IssueTagsControllerTest < ActionController::TestCase
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
    @request.env['HTTP_REFERER'] = '/update_issue_tags'
    @request.session[:user_id] = 2
    @project_1 = projects(:projects_001)
    @issue_1 = issues(:issues_001)
    @issue_2 = issues(:issues_002)
    @issue_8 = issues(:issues_008)
    @issues = [@issue_1, @issue_2, @issue_8]
    @ids = [1, 2, 8]
    @most_used_tags = %w[second third first]
    @role = roles(:roles_001) # Manager role
    @role.add_permission! :edit_tags
  end

  def test_should_get_edit_when_one_issue_chose
    compatible_xhr_request :get, :edit, ids: [1]
    assert_response :success
    assert_equal 'text/javascript', response.content_type

    html_form = response.body[/<form.+form>/].delete('\\')

    assert_select_in html_form, 'select#issue_tag_list', 1 do
      assert_select 'option[selected="selected"]', 2
      assert_select 'option[selected="selected"]', text: 'second', count: 1
      assert_select 'option[selected="selected"]', text: 'third', count: 1
    end

    assert_select_in html_form, '.most_used_tags', text: /.+second.+third.+first.+/, count: 1 do
      assert_select '.most_used_tag', 3
      @most_used_tags.each { |tag| assert_select '.most_used_tag', text: tag, count: 1 }
    end
  end

  def test_should_get_edit_when_several_issues_chose
    compatible_xhr_request :get, :edit, ids: @ids
    assert_response :success
    assert_equal 'text/javascript', response.content_type

    html_form = response.body[/<form.+form>/].delete('\\')

    assert_select_in html_form, 'select#issue_tag_list', 1 do
      assert_select 'option[selected="selected"]', 3
    end

    assert_select_in html_form, '.most_used_tags', text: /.+second.+third.+first.+/, count: 1 do
      assert_select '.most_used_tag', 3
      @most_used_tags.each { |tag| assert_select '.most_used_tag', text: tag, count: 1 }
    end
  end

  def test_should_get_not_found_when_no_ids
    compatible_xhr_request :get, :edit, ids: []
    assert_response :missing
    compatible_request :post, :update, ids: [], issue: { tag_list: [] }
    assert_response :missing
  end

  def test_should_change_issue_tags_empty_tags
    compatible_request :post, :update, ids: [1], issue: { tag_list: ['', '', ''] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_tags_added), flash[:notice]
    assert_equal [], @issue_1.tag_list
  end

  def test_should_change_issue_tags_no_tags
    compatible_request :post, :update, ids: [1], issue: { tag_list: [] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_tags_added), flash[:notice]
    assert_equal [], @issue_1.tag_list
  end

  def test_should_change_issue_tags_one_tag
    compatible_request :post, :update, ids: [1], issue: { tag_list: %w[first] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_tags_added), flash[:notice]
    assert_equal %w[first], @issue_1.tag_list
  end

  def test_should_change_issue_tags_several_tags
    compatible_request :post, :update, ids: [1], issue: { tag_list: %w[first second third] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_tags_added), flash[:notice]
    assert_equal %w[first second third], @issue_1.tag_list.sort
  end

  def test_should_bulk_change_issue_tags_no_tags
    compatible_request :post, :update, ids: @ids, issue: { tag_list: [] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_tags_added), flash[:notice]
    @issues.each { |issue| assert_equal [], issue.tag_list }
  end

  def test_should_bulk_change_issue_tags_one_tag
    compatible_request :post, :update, ids: @ids, issue: { tag_list: %w[first] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_tags_added), flash[:notice]
    @issues.each { |issue| assert_equal %w[first], issue.tag_list }
  end

  def test_should_bulk_change_issue_tags_several_tags
    compatible_request :post, :update, ids: @ids, issue: { tag_list: %w[first second third] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_tags_added), flash[:notice]
    @issues.each { |issue| assert_equal %w[first second third], issue.tag_list.sort }
  end

  def test_edit_tags_permission
    tag = 'first'
    assert_not_equal Issue.find(1).tag_list, [tag]
    assert Issue.all_tags.map(&:name).include?(tag)
    compatible_request :post, :update, ids: [1], issue: { tag_list: [tag] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_tags_added), flash[:notice]
    assert_equal Issue.find(1).tag_list, [tag]

    @role.remove_permission! :edit_tags
    tag2 = 'second'

    assert Issue.all_tags.map(&:name).include?(tag2)
    compatible_request :post, :update, ids: [1], issue: { tag_list: [tag2] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_failed_to_add_tags), flash[:error]
    assert_equal Issue.find(1).tag_list, [tag]
  end

  def test_bulk_edit_tags_permission
    tag = 'first'
    assert Issue.all_tags.map(&:name).include?(tag)
    compatible_request :post, :update, ids: [1, 2], issue: { tag_list: [tag] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_tags_added), flash[:notice]
    assert_equal Issue.find(1).tag_list, [tag]
    assert_equal Issue.find(2).tag_list, [tag]

    @role.remove_permission! :edit_tags
    tag2 = 'second'

    assert Issue.all_tags.map(&:name).include?(tag2)
    compatible_request :post, :update, ids: [1, 2], issue: { tag_list: [tag2] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_failed_to_add_tags), flash[:error]
    assert_equal Issue.find(1).tag_list, [tag]
    assert_equal Issue.find(2).tag_list, [tag]
  end

  def test_create_tags_permission
    @role.add_permission! :create_tags
    new_tag = 'enable_create_tags_permission'

    assert_not_equal Issue.find(1).tag_list, [new_tag]
    assert !Issue.all_tags.map(&:name).include?(new_tag)
    compatible_request :post, :update, ids: [1], issue: { tag_list: [new_tag] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_tags_added), flash[:notice]
    assert_equal Issue.find(1).tag_list, [new_tag]

    @role.remove_permission! :create_tags
    new_tag2 = 'disable_create_tags_permission'

    assert !Issue.all_tags.map(&:name).include?(new_tag2)
    compatible_request :post, :update, ids: [1], issue: { tag_list: [new_tag2] }
    assert_response :redirect
    assert_redirected_to action: 'update'
    assert_equal I18n.t(:notice_failed_to_add_tags), flash[:error]
    assert_equal Issue.find(1).tag_list, [new_tag]
  end
end
