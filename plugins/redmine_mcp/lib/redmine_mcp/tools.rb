# frozen_string_literal: true

module RedmineMcp
  module Tools
    # Tool-level failure reported to the MCP client as a tool result with
    # isError: true, so that the calling model can read the message and
    # correct its arguments
    class ToolError < StandardError; end

    def self.all
      [
        Whoami,
        ListProjects,
        ProjectMetadata,
        Search,
        ListIssues,
        GetIssue,
        CreateIssue,
        UpdateIssue,
        GetWikiPage
      ]
    end

    def self.find(name)
      all.detect {|tool| tool.tool_name == name}
    end
  end
end
