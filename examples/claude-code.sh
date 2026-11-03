#!/usr/bin/env bash
# Register the AGILEX Docs MCP server with Claude Code.
set -euo pipefail
claude mcp add agilex-docs --transport http https://service.agilex.ai/agilex-docs/mcp
claude mcp list | grep agilex-docs
