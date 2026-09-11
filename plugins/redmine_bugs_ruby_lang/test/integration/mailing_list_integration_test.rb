# frozen_string_literal: true

require_relative '../../../../test/test_helper'

class MailingListIntegrationTest < Redmine::IntegrationTest
  def setup
    super
    # config/configuration.yml switches every environment to SMTP
    @delivery_method = ActionMailer::Base.delivery_method
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries.clear
    @mailing_list = MailingList.create!(identifier: 'ruby-core', address: 'ruby-core@ruby-lang.org', driver_name: 'fml')
    UseOfMailingList.create!(mailing_list: @mailing_list, project: Project.find(1), receptor_name: 'default')
  end

  def teardown
    ActionMailer::Base.delivery_method = @delivery_method
  end

  def test_note_from_web_ui_is_posted_to_mailing_list
    log_user('jsmith', 'jsmith')
    patch '/issues/1', params: {issue: {notes: 'noted on the web'}}

    assert_posted_to_mailing_list issue: Issue.find(1), journal: Issue.find(1).journals.last
  end

  def test_issue_from_mcp_is_posted_to_mailing_list
    call_mcp_tool('create_issue', 'project' => 'ecookbook', 'subject' => 'created via MCP')

    assert_posted_to_mailing_list issue: Issue.order(:id).last, journal: nil
  end

  def test_note_from_mcp_is_posted_to_mailing_list
    call_mcp_tool('update_issue', 'id' => 1, 'notes' => 'noted via MCP')

    assert_posted_to_mailing_list issue: Issue.find(1), journal: Issue.find(1).journals.last
  end

  private

  def call_mcp_tool(name, arguments)
    key = Token.create!(user: User.find(2), action: 'api').value
    with_settings rest_api_enabled: '1' do
      post '/mcp', params: {jsonrpc: '2.0', id: 1, method: 'tools/call', params: {name: name, arguments: arguments}}.to_json,
                   headers: {'CONTENT_TYPE' => 'application/json', 'HTTP_X_REDMINE_API_KEY' => key}
    end
    assert_not response.parsed_body.dig('result', 'isError'), response.body
  end

  def assert_posted_to_mailing_list(issue:, journal:)
    assert MailingListMessage.exists?(mailing_list: @mailing_list, issue: issue, journal: journal)
    assert ActionMailer::Base.deliveries.any? {|mail| mail.to == [@mailing_list.address]}
  end
end
