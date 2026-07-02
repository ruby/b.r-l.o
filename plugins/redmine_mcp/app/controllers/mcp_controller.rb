# frozen_string_literal: true

# MCP (Model Context Protocol) endpoint using the Streamable HTTP transport
# in its stateless form: every JSON-RPC request is answered with a plain
# application/json response, no SSE stream and no server-side session.
#
# Authentication reuses Redmine's REST API authentication: the per-user API
# key is accepted via the X-Redmine-API-Key header, HTTP Basic (key as
# username) or an Authorization: Bearer header.
class McpController < ApplicationController
  accept_api_auth :handle

  before_action :require_login, only: :handle

  def handle
    unless request.media_type == 'application/json'
      render json: RedmineMcp::JsonRpc.error_response(nil, -32700, 'Content-Type must be application/json'), status: :bad_request
      return
    end

    server = RedmineMcp::Server.new
    payload = server.handle(request.raw_post)

    if payload.nil?
      # Notification (no id): acknowledge without a body
      head :accepted
    else
      render json: payload
    end
  end

  def method_not_allowed
    response.headers['Allow'] = 'POST'
    head :method_not_allowed
  end

  private

  # Also accept "Authorization: Bearer <api key>" so that MCP clients that
  # can only send a bearer token work out of the box. The token is only
  # treated as an API key when it actually resolves to a user, so Doorkeeper
  # OAuth tokens keep working through the regular flow.
  def api_key_from_request
    key = super
    return key if key

    token = request.headers['Authorization'].to_s[/\ABearer (.+)\z/i, 1]
    token if token && User.find_by_api_key(token)
  end
end
