# frozen_string_literal: true

module RedmineMcp
  # Stateless MCP server: dispatches JSON-RPC 2.0 messages to tool
  # implementations. One instance handles one HTTP request.
  # The authenticated user is taken from User.current, which the controller
  # sets up through Redmine's regular API authentication.
  class Server
    # Newest first. The first entry is offered when the client requests an
    # unknown version.
    PROTOCOL_VERSIONS = %w[2025-06-18 2025-03-26 2024-11-05].freeze

    INSTRUCTIONS = <<~TEXT.freeze
      MCP server for this Redmine instance. All operations run with the
      permissions of the user who owns the API key, so results are limited to
      what that user can see and do in the web UI.

      Typical workflow: call `whoami` once to confirm authentication, use
      `search` or `list_issues` to locate issues, `get_issue` to read a full
      ticket including comments, and `update_issue`/`create_issue` to write.
      Call `project_metadata` to discover valid trackers, statuses,
      priorities, categories, versions and assignees before writing.
      Issue descriptions and notes use the wiki text formatting reported by
      `whoami` (field `text_formatting`).
    TEXT

    def handle(raw_body)
      message =
        begin
          JSON.parse(raw_body.to_s)
        rescue JSON::ParserError
          return JsonRpc.error_response(nil, JsonRpc::PARSE_ERROR, 'Parse error')
        end

      case message
      when Hash
        handle_message(message)
      when Array
        # JSON-RPC batches were removed from MCP in 2025-06-18 but older
        # clients may still send them
        return JsonRpc.error_response(nil, JsonRpc::INVALID_REQUEST, 'Invalid Request') if message.empty?

        responses = message.filter_map {|m| handle_message(m)}
        responses.empty? ? nil : responses
      else
        JsonRpc.error_response(nil, JsonRpc::INVALID_REQUEST, 'Invalid Request')
      end
    end

    private

    def handle_message(message)
      unless message.is_a?(Hash) && message['jsonrpc'] == '2.0' && message['method'].is_a?(String)
        id = message.is_a?(Hash) ? message['id'] : nil
        return JsonRpc.error_response(id, JsonRpc::INVALID_REQUEST, 'Invalid Request')
      end

      id = message['id']
      params = message['params'].is_a?(Hash) ? message['params'] : {}

      # Notifications (no id) never get a response
      return nil if id.nil?

      result =
        case message['method']
        when 'initialize'
          initialize_result(params)
        when 'ping'
          {}
        when 'tools/list'
          {tools: Tools.all.map(&:definition)}
        when 'tools/call'
          tools_call(params)
        else
          return JsonRpc.error_response(id, JsonRpc::METHOD_NOT_FOUND, "Method not found: #{message['method']}")
        end
      JsonRpc.result_response(id, result)
    rescue JsonRpc::Error => e
      JsonRpc.error_response(id, e.code, e.message)
    rescue StandardError => e
      log_error(e)
      JsonRpc.error_response(id, JsonRpc::INTERNAL_ERROR, 'Internal error')
    end

    def initialize_result(params)
      requested = params['protocolVersion'].to_s
      version = PROTOCOL_VERSIONS.include?(requested) ? requested : PROTOCOL_VERSIONS.first
      {
        protocolVersion: version,
        capabilities: {tools: {listChanged: false}},
        serverInfo: {
          name: 'redmine-mcp',
          title: Setting.app_title,
          version: Redmine::Plugin.find(:redmine_mcp).version
        },
        instructions: INSTRUCTIONS
      }
    end

    def tools_call(params)
      tool = Tools.find(params['name'].to_s)
      raise JsonRpc::Error.new(JsonRpc::INVALID_PARAMS, "Unknown tool: #{params['name']}") unless tool

      arguments = params['arguments'].is_a?(Hash) ? params['arguments'] : {}
      data = tool.new(User.current).call(arguments)
      tool_result(data)
    rescue Tools::ToolError => e
      tool_error(e.message)
    rescue ActiveRecord::RecordNotFound
      tool_error('Not found or not visible to you')
    rescue ::Unauthorized
      tool_error('You are not allowed to perform this action')
    rescue StandardError => e
      log_error(e)
      tool_error('Internal error')
    end

    def tool_result(data)
      text = data.is_a?(String) ? data : JSON.pretty_generate(data)
      {content: [{type: 'text', text: text}], isError: false}
    end

    def tool_error(message)
      {content: [{type: 'text', text: message}], isError: true}
    end

    def log_error(exception)
      Rails.logger.error("[redmine_mcp] #{exception.class.name}: #{exception.message}\n  #{exception.backtrace&.first(10)&.join("\n  ")}")
    end
  end
end
