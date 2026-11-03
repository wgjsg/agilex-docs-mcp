#!/usr/bin/env bash
# End-to-end check against the live AGILEX Docs MCP endpoint.
# initialize -> tools/list -> tools/call (search_docs) -> tools/call (get_doc)
#
# Usage: ./scripts/smoke-test.sh [endpoint]
set -euo pipefail

EP="${1:-https://service.agilex.ai/agilex-docs/mcp}"
ACCEPT='Accept: application/json, text/event-stream'
CT='Content-Type: application/json'

# Stateless server, but send a session header anyway: some clients require the
# server to echo one back, and this keeps the script honest about the handshake.
SID="smoke-$(date +%s)"

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

rpc() {
  local body="$1"
  curl -sS --max-time 30 -X POST "$EP" \
    -H "$CT" -H "$ACCEPT" -H "Mcp-Session-Id: $SID" \
    -d "$body"
}

# Responses may come back as SSE ("data: {...}") or plain JSON; normalise to JSON.
strip() { sed -n 's/^data: //p;t;p' | grep -v '^$'; }

say "initialize"
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"agilex-smoke","version":"1.0"}}}'
INIT_OUT="$(rpc "$INIT" | strip)"
echo "$INIT_OUT" | head -c 600; echo
echo "$INIT_OUT" | grep -q '"serverInfo"' || { echo "FAIL: no serverInfo"; exit 1; }

say "tools/list"
TOOLS='{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
TOOLS_OUT="$(rpc "$TOOLS" | strip)"
NAMES="$(echo "$TOOLS_OUT" | grep -o '"name":"[a-z_]*"' | sed 's/.*:"//;s/"//' | sort -u | tr '\n' ' ')"
echo "tools: $NAMES"
for want in search_docs get_doc list_docs list_spaces; do
  echo "$NAMES" | grep -q "$want" || { echo "FAIL: missing tool $want"; exit 1; }
done

say "tools/call search_docs"
SEARCH='{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"search_docs","arguments":{"query":"piper CAN 波特率","limit":2}}}'
SEARCH_OUT="$(rpc "$SEARCH" | strip)"
echo "$SEARCH_OUT" | head -c 900; echo
echo "$SEARCH_OUT" | grep -q '"doc_id"' || { echo "FAIL: no doc_id in search result"; exit 1; }

DOC_ID="$(echo "$SEARCH_OUT" | grep -o '"doc_id":"[^"]*"' | head -1 | sed 's/.*:"//;s/"//')"
echo "first hit: $DOC_ID"

say "tools/call get_doc (paginated)"
GETDOC="{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"get_doc\",\"arguments\":{\"doc_id\":\"$DOC_ID\",\"max_chars\":1200}}}"
GETDOC_OUT="$(rpc "$GETDOC" | strip)"
echo "$GETDOC_OUT" | head -c 700; echo
echo "$GETDOC_OUT" | grep -q '"truncated"' || { echo "FAIL: no truncation metadata"; exit 1; }

say "PASS — endpoint is serving 4 tools and paginating correctly"
