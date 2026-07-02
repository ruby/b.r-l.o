# frozen_string_literal: true

require_relative '../../../../test/test_helper'

class McpEndpointTest < Redmine::IntegrationTest
  def setup
    super
    Setting.rest_api_enabled = '1'
    Setting.notified_events = []
    @user = User.find(2) # jsmith, member of ecookbook and onlinestore
    @key = Token.create!(user: @user, action: 'api').value
  end

  def teardown
    Setting.rest_api_enabled = '0'
  end

  # someone (user 7) has no memberships, so private projects are invisible
  def outsider_key
    @outsider_key ||= Token.create!(user: User.find(7), action: 'api').value
  end

  def test_get_is_not_allowed
    get '/mcp'
    assert_response :method_not_allowed
    assert_equal 'POST', response.headers['Allow']
  end

  def test_anonymous_request_is_rejected
    mcp_post({jsonrpc: '2.0', id: 1, method: 'ping'}, key: nil)
    assert_response :unauthorized
  end

  def test_invalid_api_key_is_rejected
    mcp_post({jsonrpc: '2.0', id: 1, method: 'ping'}, key: 'wrong-key')
    assert_response :unauthorized
  end

  def test_authentication_with_bearer_token
    mcp_post({jsonrpc: '2.0', id: 1, method: 'ping'}, key: nil,
             headers: {'HTTP_AUTHORIZATION' => "Bearer #{@key}"})
    assert_response :success
    assert_equal({}, JSON.parse(response.body)['result'])
  end

  def test_rejects_non_json_content_type
    post '/mcp', params: 'jsonrpc',
                 headers: {'CONTENT_TYPE' => 'text/plain', 'HTTP_X_REDMINE_API_KEY' => @key}
    assert_response :bad_request
  end

  def test_malformed_json_is_rejected
    # Rails' JSON parameter parsing middleware rejects the body before the
    # controller runs
    post '/mcp', params: '{invalid',
                 headers: {'CONTENT_TYPE' => 'application/json', 'HTTP_X_REDMINE_API_KEY' => @key}
    assert_response :bad_request
  end

  def test_empty_body_returns_parse_error
    post '/mcp', params: '',
                 headers: {'CONTENT_TYPE' => 'application/json', 'HTTP_X_REDMINE_API_KEY' => @key}
    assert_response :success
    assert_equal(-32700, JSON.parse(response.body)['error']['code'])
  end

  def test_unknown_method
    response_json = rpc('no/such/method')
    assert_equal(-32601, response_json['error']['code'])
  end

  def test_notification_is_accepted_without_body
    mcp_post({jsonrpc: '2.0', method: 'notifications/initialized'})
    assert_response :accepted
    assert_empty response.body
  end

  def test_initialize
    result = rpc('initialize', {'protocolVersion' => '2025-06-18'})['result']
    assert_equal '2025-06-18', result['protocolVersion']
    assert_equal 'redmine-mcp', result['serverInfo']['name']
    assert result['capabilities'].key?('tools')
  end

  def test_initialize_with_unsupported_protocol_version_offers_latest
    result = rpc('initialize', {'protocolVersion' => '1999-01-01'})['result']
    assert_equal RedmineMcp::Server::PROTOCOL_VERSIONS.first, result['protocolVersion']
  end

  def test_tools_list
    result = rpc('tools/list')['result']
    names = result['tools'].map {|t| t['name']}
    expected = %w[whoami list_projects project_metadata search list_issues
                  get_issue create_issue update_issue get_wiki_page]
    assert_equal expected.sort, names.sort
    result['tools'].each do |tool|
      assert tool['description'].present?, "#{tool['name']} has no description"
      assert_equal 'object', tool['inputSchema']['type']
    end
  end

  def test_whoami
    data = call_tool('whoami')
    assert_equal 'jsmith', data['login']
    assert_equal @user.id, data['id']
    assert_includes data['member_of'], 'ecookbook'
  end

  def test_list_projects
    data = call_tool('list_projects')
    identifiers = data['projects'].map {|p| p['identifier']}
    assert_includes identifiers, 'ecookbook'
    assert_includes identifiers, 'onlinestore'
  end

  def test_list_projects_excludes_invisible_private_projects
    data = call_tool('list_projects', {}, key: outsider_key)
    identifiers = data['projects'].map {|p| p['identifier']}
    assert_includes identifiers, 'ecookbook'
    # onlinestore is private and someone is not a member
    assert_not_includes identifiers, 'onlinestore'
  end

  def test_project_metadata
    data = call_tool('project_metadata', {'project' => 'ecookbook'})
    assert_includes data['trackers'], 'Bug'
    assert data['statuses'].any? {|s| s['closed']}
    assert data['priorities'].any?
    assert data['assignable_users'].any? {|u| u['login'] == 'jsmith'}
    assert data['permissions']['add_issues']
  end

  def test_list_issues_with_filters
    data = call_tool('list_issues', {'project' => 'ecookbook', 'status' => 'any', 'limit' => 5})
    assert_operator data['total_count'], :>, 0
    assert_operator data['issues'].size, :<=, 5
    data = call_tool('list_issues', {'assigned_to' => 'me', 'status' => 'any'})
    data['issues'].each do |issue|
      assert_equal @user.name, issue['assigned_to']
    end
  end

  def test_list_issues_rejects_unknown_status
    data = call_tool('list_issues', {'status' => 'Nonexistent'}, error: true)
    assert_match /Unknown status/, data
  end

  # 'any' is the only no-filter keyword; 'all'/'*' are not aliases
  def test_list_issues_all_is_not_a_status_alias
    data = call_tool('list_issues', {'status' => 'all'}, error: true)
    assert_match /Unknown status/, data
  end

  def test_search
    data = call_tool('search', {'q' => 'recipe'})
    assert_operator data['total_count'], :>, 0
    assert data['results'].all? {|r| r['url'].present?}
  end

  def test_get_issue_with_journals
    Journal.create!(journalized: Issue.find(1), user: User.find(1), notes: 'a public note')
    data = call_tool('get_issue', {'id' => 1})
    assert_equal 1, data['id']
    assert data['subject'].present?
    assert data['url'].end_with?('/issues/1')
    assert data['journals'].any? {|j| j['notes'] == 'a public note'}
  end

  def test_get_issue_hides_private_notes
    Role.find(1).remove_permission!(:view_private_notes)
    Journal.create!(journalized: Issue.find(1), user: User.find(1),
                    notes: 'secret note', private_notes: true)
    data = call_tool('get_issue', {'id' => 1})
    assert(data['journals'].none? {|j| j['notes'] == 'secret note'})
  end

  def test_get_issue_not_visible
    issue = Issue.generate!(project_id: 2) # onlinestore, invisible to someone
    data = call_tool('get_issue', {'id' => issue.id}, key: outsider_key, error: true)
    assert_match /not found or not visible/, data
  end

  def test_create_issue
    assert_difference 'Issue.count' do
      data = call_tool('create_issue', {
        'project' => 'ecookbook',
        'subject' => 'MCP created issue',
        'description' => 'created through MCP',
        'tracker' => 'Bug'
      })
      assert data['created']
      assert_equal 'MCP created issue', data['subject']
      assert_equal 'Bug', data['tracker']
    end
    issue = Issue.order(:id).last
    assert_equal @user, issue.author
  end

  def test_create_issue_without_permission
    data = call_tool('create_issue', {'project' => 'onlinestore', 'subject' => 'x'},
                     key: outsider_key, error: true)
    assert_match /not found or not visible/, data
  end

  def test_create_issue_with_unknown_tracker
    data = call_tool('create_issue',
                     {'project' => 'ecookbook', 'subject' => 'x', 'tracker' => 'Nope'},
                     error: true)
    assert_match /Unknown tracker/, data
  end

  def test_update_issue_add_note
    assert_difference 'Journal.count' do
      data = call_tool('update_issue', {'id' => 1, 'notes' => 'noted via MCP'})
      assert data['updated']
    end
    assert_equal 'noted via MCP', Issue.find(1).journals.last.notes
  end

  def test_update_issue_change_status
    issue = Issue.find(1)
    allowed = issue.new_statuses_allowed_to(@user)
    skip 'no workflow transition available in fixtures' if allowed.empty?

    target = allowed.first
    data = call_tool('update_issue', {'id' => 1, 'status' => target.name})
    assert_equal target.name, data['status']
    assert_equal target, issue.reload.status
  end

  def test_update_issue_rejects_disallowed_status
    WorkflowTransition.delete_all
    issue = Issue.find(1)
    forbidden = IssueStatus.all.detect {|s| s != issue.status}

    data = call_tool('update_issue', {'id' => 1, 'status' => forbidden.name}, error: true)
    assert_match /Transitions allowed to you/, data
    assert_not_equal forbidden, issue.reload.status
  end

  def test_update_issue_requires_something_to_do
    data = call_tool('update_issue', {'id' => 1}, error: true)
    assert_match /Nothing to do/, data
  end

  def test_get_wiki_page
    data = call_tool('get_wiki_page', {'project' => 'ecookbook'})
    assert_equal 'CookBook_documentation', data['title']
    assert data['text'].present?
  end

  def test_get_wiki_page_list
    data = call_tool('get_wiki_page', {'project' => 'ecookbook', 'list' => true})
    assert_includes data['pages'], 'CookBook_documentation'
  end

  private

  def mcp_post(body, key: @key, headers: {})
    all_headers = {'CONTENT_TYPE' => 'application/json'}
    all_headers['HTTP_X_REDMINE_API_KEY'] = key if key
    post '/mcp', params: body.to_json, headers: all_headers.merge(headers)
  end

  def rpc(method, params = {}, key: @key)
    mcp_post({jsonrpc: '2.0', id: 1, method: method, params: params}, key: key)
    assert_response :success
    JSON.parse(response.body)
  end

  # Calls a tool and returns the parsed JSON payload, or the raw error text
  # when error: true
  def call_tool(name, arguments = {}, key: @key, error: false)
    response_json = rpc('tools/call', {'name' => name, 'arguments' => arguments}, key: key)
    assert_nil response_json['error'], "unexpected JSON-RPC error: #{response_json['error'].inspect}"
    result = response_json['result']
    text = result['content'].first['text']
    if error
      assert result['isError'], "expected a tool error but got: #{text}"
      text
    else
      assert_not result['isError'], "unexpected tool error: #{text}"
      JSON.parse(text)
    end
  end
end
