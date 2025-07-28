#!/usr/bin/env ruby
# frozen_string_literal: true

# MCP (Model Context Protocol) Server for Assignman
# This server provides tools to execute use cases via MCP protocol
# Usage: bundle exec rails r mcp.rb

require 'fast_mcp'

# Initialize Rails environment
Rails.application.eager_load!

# Configure the MCP server
server = FastMcp::Server.new(
  name: 'assignman-mcp',
  version: '1.0.0'
)

# Load all tools from app/tools directory
Dir[Rails.root.join('app/tools/*_tool.rb')].each do |file|
  # Extract tool class name from filename
  tool_class_name = File.basename(file, '.rb').camelize
  tool_class = tool_class_name.constantize
  
  # Register the tool with the server
  server.register_tool(tool_class)
end

# Start the MCP server
server.start