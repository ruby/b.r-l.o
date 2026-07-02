# frozen_string_literal: true

module RedmineMcp
  # Minimal JSON-RPC 2.0 message helpers for the MCP endpoint
  module JsonRpc
    PARSE_ERROR      = -32700
    INVALID_REQUEST  = -32600
    METHOD_NOT_FOUND = -32601
    INVALID_PARAMS   = -32602
    INTERNAL_ERROR   = -32603

    # Protocol-level error that is reported to the client as a JSON-RPC error
    class Error < StandardError
      attr_reader :code

      def initialize(code, message)
        @code = code
        super(message)
      end
    end

    def self.result_response(id, result)
      {jsonrpc: '2.0', id: id, result: result}
    end

    def self.error_response(id, code, message)
      {jsonrpc: '2.0', id: id, error: {code: code, message: message}}
    end
  end
end
