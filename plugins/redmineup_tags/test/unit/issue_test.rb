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

class RedmineupTags::Patches::IssueTest < ActiveSupport::TestCase
  fixtures :users, :projects, :issues, :issue_statuses, :enumerations, :trackers

  def setup
    # run as the admin
    User.stubs(:current).returns(users(:users_001))

    @project_a = Project.find 1
    @project_b = Project.find 3
  end

  test 'patch was applied' do
    assert_respond_to Issue, :available_tags, 'Issue has available_tags getter'
    assert_respond_to Issue.new, :tags, 'Issue instance has tags getter'
    assert_respond_to Issue.new, :tags=, 'Issue instance has tags setter'
    assert_respond_to Issue.new, :tag_list=, 'Issue instance has tag_list setter'
  end

  test 'available tags should return list of distinct tags' do
    assert_equal 3, Issue.available_tags.to_a.size
  end

  test 'available tags should allow list tags of open issues only' do
    assert_equal 2, Issue.available_tags(open_only: true).to_a.size
  end

  test 'available tags should allow list tags of specific project only' do
    assert_equal 3, Issue.available_tags(project: @project_a).to_a.size
    assert_equal 2, Issue.available_tags(project: @project_b).to_a.size

    assert_equal 2, Issue.available_tags(open_only: true, project: @project_a).to_a.size
    assert_equal 2, Issue.available_tags(open_only: true, project: @project_b).to_a.size
  end

  test 'available tags should allow list tags found by name' do
    assert_equal 2, Issue.available_tags(name_like: 'i').to_a.size
    assert_equal 1, Issue.available_tags(name_like: 'rd').to_a.size
    assert_equal 2, Issue.available_tags(name_like: 's').to_a.size
    assert_equal 1, Issue.available_tags(name_like: 'e').to_a.size

    assert_equal 1, Issue.available_tags(name_like: 'f', project: @project_a).to_a.size
    assert_equal 0, Issue.available_tags(name_like: 'b', project: @project_a).to_a.size
    assert_equal 1, Issue.available_tags(name_like: 'sec', open_only: true, project: @project_a).to_a.size
    assert_equal 0, Issue.available_tags(name_like: 'fir', open_only: true, project: @project_a).to_a.size
  end

  test 'Issue.all_tags should return all tags kind of Issue' do
    tags = Issue.all_tags.map(&:name)
    assert_equal %w[first second third], tags
  end
end
