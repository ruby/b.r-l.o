# frozen_string_literal: true

require 'redmine'

Redmine::Plugin.register :redmine_mcp do
  name 'Redmine MCP Server'
  author 'Hiroshi SHIBATA'
  description 'Exposes a Model Context Protocol (MCP) endpoint at /mcp so that ' \
              'AI coding agents can search, read and update issues on this Redmine ' \
              'using per-user REST API keys.'
  version '1.0.0'
  url 'https://github.com/hsbt/redmine_mcp'
  author_url 'https://github.com/hsbt/redmine_mcp'

  requires_redmine version_or_higher: '5.0'
end
