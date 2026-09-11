# frozen_string_literal: true

require_relative '../../../../test/test_helper'

class McpEndpointTest < Redmine::IntegrationTest
  # Listeners cannot be unregistered, so this one records only while a test
  # sets calls
  class IssueHookRecorder < Redmine::Hook::Listener
    cattr_accessor :calls

    %i[controller_issues_new_before_save controller_issues_new_after_save
       controller_issues_edit_before_save controller_issues_edit_after_save].each do |hook|
      define_method(hook) do |context|
        calls&.push(hook: hook, context: context, saved: (context[:journal] || context[:issue]).persisted?)
      end
    end
  end

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

  def test_invalid_bearer_token_is_rejected
    mcp_post({jsonrpc: '2.0', id: 1, method: 'ping'}, key: nil,
             headers: {'HTTP_AUTHORIZATION' => 'Bearer not-a-real-key'})
    assert_response :unauthorized
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
                  get_issue create_issue update_issue update_journal link_issues unlink_issues
                  get_wiki_page]
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

  def test_list_issues_with_subject_filter
    match = call_tool('list_issues', {'project' => 'ecookbook', 'status' => 'any', 'subject' => 'recipe'})
    assert_operator match['total_count'], :>, 0
    none = call_tool('list_issues', {'project' => 'ecookbook', 'status' => 'any', 'subject' => 'zzznomatchzzz'})
    assert_equal 0, none['total_count']
  end

  def test_list_issues_with_updated_after_filter
    past = call_tool('list_issues', {'status' => 'any', 'updated_after' => '2000-01-01'})
    assert_operator past['total_count'], :>, 0
    future = call_tool('list_issues', {'status' => 'any', 'updated_after' => '2999-01-01'})
    assert_equal 0, future['total_count']
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

  # Guards the batched id->name resolution for attribute change details
  def test_get_issue_resolves_named_detail_changes
    issue = Issue.find(1)
    issue.init_journal(User.find(1))
    issue.assigned_to_id = 3
    issue.status_id = 2
    issue.save!

    details = call_tool('get_issue', {'id' => 1})['journals'].flat_map {|j| j['details'] || []}
    assert_equal Principal.find(3).name, details.detect {|d| d['attribute'] == 'assigned_to'}['new_value']
    assert_equal IssueStatus.find(2).name, details.detect {|d| d['attribute'] == 'status'}['new_value']
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

  def test_create_issue_fires_issues_controller_hooks
    calls = record_issue_hooks do
      call_tool('create_issue', {'project' => 'ecookbook', 'subject' => 'hooked'})
    end
    assert_equal [[:controller_issues_new_before_save, false], [:controller_issues_new_after_save, true]],
                 calls.map {|c| [c[:hook], c[:saved]]}
    assert_equal Issue.order(:id).last, calls.last[:context][:issue]
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

  def test_update_issue_fires_issues_controller_hooks
    calls = record_issue_hooks do
      call_tool('update_issue', {'id' => 1, 'notes' => 'hooked'})
    end
    assert_equal [[:controller_issues_edit_before_save, false], [:controller_issues_edit_after_save, true]],
                 calls.map {|c| [c[:hook], c[:saved]]}
    assert_equal 'hooked', calls.last[:context][:journal].notes
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

  def test_update_issue_private_note
    Role.find(1).add_permission!(:set_notes_private)
    data = call_tool('update_issue', {'id' => 1, 'notes' => 'secret', 'private_notes' => true})
    assert data['updated']
    journal = Issue.find(1).journals.last
    assert journal.private_notes?
    assert_equal 'secret', journal.notes
  end

  # Without set_notes_private, safe_attributes= would silently post the note
  # publicly; the tool must reject it instead of leaking it.
  def test_update_issue_private_note_without_permission_is_rejected
    Role.find(1).remove_permission!(:set_notes_private)
    assert_no_difference 'Journal.count' do
      data = call_tool('update_issue',
                       {'id' => 1, 'notes' => 'secret', 'private_notes' => true}, error: true)
      assert_match /not allowed to add private notes/, data
    end
  end

  def test_update_issue_custom_field
    data = call_tool('update_issue',
                     {'id' => 1, 'custom_fields' => {'Searchable field' => 'updated via MCP'}})
    assert data['updated']
    assert_equal 'updated via MCP', Issue.find(1).custom_field_value(2)
  end

  def test_update_issue_unknown_custom_field_is_rejected
    data = call_tool('update_issue',
                     {'id' => 1, 'custom_fields' => {'No Such Field' => 'x'}}, error: true)
    assert_match /Unknown custom field/, data
  end

  def test_update_journal_rewrites_own_note
    Role.find(1).add_permission!(:edit_own_issue_notes)
    assert_no_difference 'Journal.count' do
      data = call_tool('update_journal', {'journal_id' => 2, 'notes' => 'rewritten via MCP'})
      assert data['updated']
      assert_equal 1, data['issue_id']
      assert_equal 'rewritten via MCP', data['notes']
    end
    journal = Journal.find(2)
    assert_equal 'rewritten via MCP', journal.notes
    assert_equal @user, journal.updated_by
  end

  def test_update_journal_rewrites_another_users_note
    Role.find(1).add_permission!(:edit_issue_notes)
    data = call_tool('update_journal', {'journal_id' => 1, 'notes' => 'rewritten by a manager'})
    assert data['updated']
    assert_equal 'rewritten by a manager', Journal.find(1).notes
  end

  def test_update_journal_own_note_without_permission_is_rejected
    Role.find(1).remove_permission!(:edit_own_issue_notes, :edit_issue_notes)
    data = call_tool('update_journal', {'journal_id' => 2, 'notes' => 'nope'}, error: true)
    assert_match /edit_own_issue_notes/, data
    assert_not_equal 'nope', Journal.find(2).notes
  end

  # edit_own_issue_notes must not be enough to rewrite someone else's comment
  def test_update_journal_another_users_note_needs_edit_issue_notes
    Role.find(1).add_permission!(:edit_own_issue_notes)
    Role.find(1).remove_permission!(:edit_issue_notes)
    data = call_tool('update_journal', {'journal_id' => 1, 'notes' => 'nope'}, error: true)
    assert_match /edit_issue_notes/, data
    assert_not_equal 'nope', Journal.find(1).notes
  end

  def test_update_journal_requires_something_to_do
    data = call_tool('update_journal', {'journal_id' => 2}, error: true)
    assert_match /Nothing to do/, data
  end

  def test_update_journal_rejects_empty_notes
    Role.find(1).add_permission!(:edit_own_issue_notes)
    data = call_tool('update_journal', {'journal_id' => 2, 'notes' => ''}, error: true)
    assert_match /cannot be empty/, data
    assert Journal.find(2).notes.present?
  end

  def test_update_journal_toggles_private_notes
    Role.find(1).add_permission!(:edit_own_issue_notes)
    notes = Journal.find(2).notes
    data = call_tool('update_journal', {'journal_id' => 2, 'private_notes' => true})
    assert data['private_notes']
    assert Journal.find(2).private_notes?
    assert_equal notes, Journal.find(2).notes
  end

  def test_update_journal_private_notes_without_permission_is_rejected
    Role.find(1).add_permission!(:edit_own_issue_notes)
    Role.find(1).remove_permission!(:set_notes_private)
    data = call_tool('update_journal', {'journal_id' => 2, 'private_notes' => true}, error: true)
    assert_match /set_notes_private/, data
    assert_not Journal.find(2).private_notes?
  end

  # journal 5 is on issue 14, a private issue someone (user 7) cannot see
  def test_update_journal_with_invisible_journal
    data = call_tool('update_journal', {'journal_id' => 5, 'notes' => 'nope'},
                     key: outsider_key, error: true)
    assert_match /not found or not visible/, data
  end

  # issue_relation_002 links issues 2 and 3
  def test_get_issue_reports_relation_ids
    related = call_tool('get_issue', {'id' => 2})['related_issues']
    assert_equal({'id' => 3, 'subject' => Issue.find(3).subject, 'status' => Issue.find(3).status.name,
                  'relation_type' => 'relates', 'relation_id' => 2},
                 related.detect {|r| r['id'] == 3})
  end

  def test_link_issues
    assert_difference 'IssueRelation.count' do
      data = call_tool('link_issues', {'issue_id' => 1, 'target_issue_id' => 2})
      assert data['linked']
      assert_equal 'relates', data['relation_type']
      assert_equal Issue.find(1).subject, data['issue']['subject']
      assert_equal Issue.find(2).subject, data['target_issue']['subject']
    end
    assert IssueRelation.find_by(issue_from_id: 1, issue_to_id: 2, relation_type: 'relates')
    # both issues record the new relation in their history, as in the web UI
    detail = Issue.find(1).journals.last.details.last
    assert_equal ['relation', 'relates', '2'], [detail.property, detail.prop_key, detail.value]
  end

  def test_link_issues_with_delay
    data = call_tool('link_issues',
                     {'issue_id' => 1, 'target_issue_id' => 2, 'relation_type' => 'precedes', 'delay' => 3})
    assert_equal 'precedes', data['relation_type']
    assert_equal 3, data['delay']
    assert_equal 3, IssueRelation.find(data['relation_id']).delay
  end

  # Redmine stores 'follows' as the reverse 'precedes' relation
  def test_link_issues_with_reverse_relation_type
    data = call_tool('link_issues',
                     {'issue_id' => 1, 'target_issue_id' => 2, 'relation_type' => 'follows'})
    assert_equal 'follows', data['relation_type']
    relation = IssueRelation.find(data['relation_id'])
    assert_equal [2, 1, 'precedes'], [relation.issue_from_id, relation.issue_to_id, relation.relation_type]
  end

  def test_link_issues_rejects_an_existing_relation
    assert_no_difference 'IssueRelation.count' do
      data = call_tool('link_issues', {'issue_id' => 2, 'target_issue_id' => 3}, error: true)
      assert_match /already linked as 'relates'/, data
    end
  end

  def test_link_issues_rejects_unknown_relation_type
    data = call_tool('link_issues',
                     {'issue_id' => 1, 'target_issue_id' => 2, 'relation_type' => 'mentions'}, error: true)
    assert_match /Unknown relation_type/, data
  end

  def test_link_issues_rejects_self_link
    data = call_tool('link_issues', {'issue_id' => 1, 'target_issue_id' => 1}, error: true)
    assert_match /link issue #1 to itself/, data
  end

  def test_link_issues_rejects_delay_on_other_relation_types
    data = call_tool('link_issues',
                     {'issue_id' => 1, 'target_issue_id' => 2, 'delay' => 3}, error: true)
    assert_match /delay only applies to/, data
  end

  def test_link_issues_reports_validation_errors
    child = Issue.generate!(project_id: 1, parent_issue_id: 1)
    assert_no_difference 'IssueRelation.count' do
      data = call_tool('link_issues', {'issue_id' => 1, 'target_issue_id' => child.id}, error: true)
      assert_match /Could not link #1 to ##{child.id}: An issue cannot be linked/, data
    end
  end

  def test_link_issues_without_permission
    Role.find(1).remove_permission!(:manage_issue_relations)
    assert_no_difference 'IssueRelation.count' do
      data = call_tool('link_issues', {'issue_id' => 1, 'target_issue_id' => 2}, error: true)
      assert_match /not allowed to manage the relations/, data
    end
  end

  def test_link_issues_with_invisible_target
    target = Issue.generate!(project_id: 2) # onlinestore, invisible to someone
    data = call_tool('link_issues', {'issue_id' => 1, 'target_issue_id' => target.id},
                     key: outsider_key, error: true)
    assert_match /not found or not visible/, data
  end

  def test_unlink_issues_by_issue_pair
    assert_difference 'IssueRelation.count', -1 do
      data = call_tool('unlink_issues', {'issue_id' => 2, 'target_issue_id' => 3})
      assert data['unlinked']
      assert_equal 2, data['relation_id']
      assert_equal 'relates', data['relation_type']
    end
    assert_nil IssueRelation.find_by_id(2)
    detail = Issue.find(2).journals.last.details.last
    assert_equal ['relation', 'relates', '3'], [detail.property, detail.prop_key, detail.old_value]
  end

  def test_unlink_issues_by_relation_id
    assert_difference 'IssueRelation.count', -1 do
      data = call_tool('unlink_issues', {'relation_id' => 2})
      assert_equal 3, data['target_issue']['id']
    end
  end

  def test_unlink_issues_requires_arguments
    data = call_tool('unlink_issues', {}, error: true)
    assert_match /Provide relation_id/, data
  end

  def test_unlink_issues_when_not_linked
    data = call_tool('unlink_issues', {'issue_id' => 1, 'target_issue_id' => 2}, error: true)
    assert_match /are not linked/, data
  end

  def test_unlink_issues_without_permission
    Role.find(1).remove_permission!(:manage_issue_relations)
    assert_no_difference 'IssueRelation.count' do
      data = call_tool('unlink_issues', {'issue_id' => 2, 'target_issue_id' => 3}, error: true)
      assert_match /not allowed to manage the relations/, data
    end
  end

  def test_unlink_issues_with_invisible_relation
    relation = IssueRelation.create!(issue_from: Issue.generate!(project_id: 2),
                                     issue_to: Issue.generate!(project_id: 2))
    assert_no_difference 'IssueRelation.count' do
      data = call_tool('unlink_issues', {'relation_id' => relation.id}, key: outsider_key, error: true)
      assert_match /not found or not visible/, data
    end
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

  def record_issue_hooks
    IssueHookRecorder.calls = []
    yield
    IssueHookRecorder.calls
  ensure
    IssueHookRecorder.calls = nil
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
