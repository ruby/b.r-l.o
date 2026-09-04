# Redmine MCP Server

This plugin adds a [Model Context Protocol](https://modelcontextprotocol.io/) endpoint to Redmine so that AI coding agents (Claude Code, Claude.ai, and other MCP clients) can search, read, create and update issues and read wiki pages.

## Endpoint

```
POST /mcp
```

The endpoint implements the Streamable HTTP transport in its stateless form. Every JSON-RPC request is answered with a single `application/json` response. `GET /mcp` returns `405 Method Not Allowed` because the server never opens SSE streams.

## Authentication

Requests are authenticated with the per-user Redmine REST API key. Users can find or generate their key on the "My account" page (`/my/account`, right sidebar). `Administration > Settings > API > Enable REST web service` must be enabled.

The key is accepted in any of the following forms:

- `X-Redmine-API-Key: <key>` header (the standard Redmine way)
- `Authorization: Bearer <key>` header (for MCP clients that only support bearer tokens)
- HTTP Basic authentication with the key as the username

Anonymous access is rejected with `401`. Every tool call runs with the permissions of the key owner, so the results are exactly what that user can see and do in the web UI. Private issues, private notes and workflow rules are all enforced by the regular Redmine permission layer.

## Client setup

Claude Code:

```
claude mcp add --transport http bugs-ruby https://bugs.ruby-lang.org/mcp \
  --header "X-Redmine-API-Key: YOUR_API_KEY"
```

Any other MCP client: configure a Streamable HTTP server with URL `https://bugs.ruby-lang.org/mcp` and the header above.

## Tools

| Tool | Purpose |
|------|---------|
| `whoami` | Verify authentication, report text formatting and memberships |
| `list_projects` | List visible projects and their identifiers |
| `project_metadata` | Valid trackers, statuses, priorities, categories, versions, assignees and your permissions in a project |
| `search` | Full-text search over issues (including notes), wiki pages and more |
| `list_issues` | Structured issue filtering (project, status, tracker, assignee, author, dates) |
| `get_issue` | One issue in full: description, custom fields, comments, history, relations, attachments |
| `create_issue` | Create an issue (requires `add_issues` permission) |
| `update_issue` | Comment on an issue and/or change attributes, with workflow validation |
| `update_journal` | Rewrite an existing comment, replacing its text (not an append) |
| `link_issues` | Relate two issues (relates, blocks, precedes, duplicates, copied) |
| `unlink_issues` | Remove a relation between two issues |
| `get_wiki_page` | Read a wiki page or list all page titles |

## Tests

```
bundle exec rake redmine:plugins:test NAME=redmine_mcp
```
