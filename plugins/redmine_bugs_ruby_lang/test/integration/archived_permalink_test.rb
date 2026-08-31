# frozen_string_literal: true

require_relative '../../../../test/test_helper'

class ArchivedPermalinkTest < Redmine::IntegrationTest
  def setup
    super
    Project.find(1).archive
  end

  def test_anonymous_can_read_an_archived_issue_by_permalink
    get '/issues/1'

    assert_response :success
    assert_select 'div.subject h3', :text => 'Cannot print recipes'
  end

  def test_archived_project_page_stays_denied
    get '/projects/ecookbook'

    assert_response :forbidden
  end

  def test_archived_project_issue_list_stays_denied
    get '/projects/ecookbook/issues'

    assert_response :forbidden
  end

  def test_archived_issue_is_absent_from_the_global_issue_list
    get '/issues'

    assert_response :success
    assert_select 'tr#issue-1', 0
  end

  def test_archived_issue_is_absent_from_the_visible_scope
    assert_nil Issue.visible(User.find(1)).find_by_id(1)
  end

  def test_archived_issue_stays_read_only
    log_user('jsmith', 'jsmith')
    get '/issues/1/edit'

    assert_response :forbidden
  end
end
