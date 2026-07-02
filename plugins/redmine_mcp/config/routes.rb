# frozen_string_literal: true

Rails.application.routes.draw do
  post 'mcp', to: 'mcp#handle', defaults: {format: 'json'}
  match 'mcp', to: 'mcp#method_not_allowed', via: [:get, :delete, :put, :patch], defaults: {format: 'json'}
end
