#!/usr/bin/env bash
# End-to-end check against the live AGILEX Docs MCP endpoint.
# initialize -> tools/list -> tools/call (search_docs) -> tools/call (get_doc)
#
# Usage: ./scripts/smoke-test.sh [endpoint]
#
# Requires: curl, python3 (stdlib only).
set -euo pipefail

EP="${1:-https://service.agilex.ai/agilex-docs/mcp}"
PROTO="2025-06-18"
SID="smoke-$(date +%s)-$$"

say() { printf '\n\033[1m== %s\033[0m\n' "$*"; }

# POST one JSON-RPC frame and print the JSON result (SSE frames unwrapped).
# Sends the headers a conforming client sends: session id and the negotiated
# protocol version (the latter is required on every request after initialize).
rpc() {
  local body="$1"
  curl -sS --max-time 30 -X POST "$EP" \
    -H 'Content-Type: application/json' \
    -H 'Accept: application/json, text/event-stream' \
    -H "Mcp-Session-Id: $SID" \
    -H "MCP-Protocol-Version: $PROTO" \
    -d "$body" \
  | python3 -c '
import json, sys
raw = sys.stdin.read()
# The server may answer as SSE ("event: message\ndata: {...}") or plain JSON.
for line in raw.splitlines():
    line = line.strip()
    if line.startswith("data:"):
        line = line[5:].strip()
    if not line or line.startswith("event:") or line.startswith("id:"):
        continue
    try:
        msg = json.loads(line)
    except json.JSONDecodeError:
        continue
    if "error" in msg:
        print("RPC ERROR:", json.dumps(msg["error"], ensure_ascii=False), file=sys.stderr)
        sys.exit(1)
    print(json.dumps(msg.get("result", {}), ensure_ascii=False))
    break
else:
    print("no JSON-RPC frame in response:", raw[:400], file=sys.stderr)
    sys.exit(1)
'
}

# Tool payloads arrive as {"content":[{"type":"text","text":"<json string>"}]}.
# Print the inner payload as JSON.
payload() {
  python3 -c '
import json, sys
res = json.load(sys.stdin)
items = res.get("content") or []
if not items:
    print(json.dumps(res, ensure_ascii=False)); sys.exit(0)
text = items[0].get("text", "")
try:
    print(json.dumps(json.loads(text), ensure_ascii=False))
except json.JSONDecodeError:
    print(json.dumps({"raw": text}, ensure_ascii=False))
'
}

say "initialize"
INIT='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"agilex-smoke","version":"1.0"}}}'
INIT_OUT="$(rpc "$INIT")"
echo "$INIT_OUT" | python3 -c '
import json, sys
r = json.load(sys.stdin)
si = r.get("serverInfo") or {}
print("server:", si.get("name"), si.get("version"), "| protocol:", r.get("protocolVersion"))
print("instructions:", (r.get("instructions") or "").splitlines()[0])
assert si.get("name"), "no serverInfo.name"
'
echo "  -> instructions present, serverInfo parsed"

say "notifications/initialized"
# 规范要求客户端在 initialize 之后发这条通知；无状态服务容忍缺失，
# 但验证脚本应模拟真实客户端，否则客户端相关缺陷测不出来。
rpc '{"jsonrpc":"2.0","method":"notifications/initialized"}' >/dev/null || true
echo "  sent"

say "tools/list"
TOOLS='{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}'
TOOLS_OUT="$(rpc "$TOOLS")"
python3 -c '
import json, sys
r = json.load(sys.stdin)
tools = r.get("tools", [])
names = sorted(t["name"] for t in tools)
print("tools:", " ".join(names))
want = {"search_docs", "find_in_doc", "get_doc", "list_docs", "list_spaces"}
missing = want - set(names)
assert not missing, "missing tools: %s" % sorted(missing)
for t in tools:
    assert t.get("description"), "%s has no description" % t.get("name")
    assert t.get("inputSchema"), "%s has no inputSchema" % t.get("name")
print("all five tools expose description + inputSchema")
' <<<"$TOOLS_OUT"

say "tools/call search_docs"
SEARCH='{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"search_docs","arguments":{"query":"piper CAN 波特率","limit":2}}}'
PAYLOAD="$(rpc "$SEARCH" | payload)"
DOC_ID="$(python3 -c '
import json, sys
d = json.load(sys.stdin)
hits = d.get("results") or []
print("  hits: %d" % len(hits), file=sys.stderr)
for h in hits:
    print("  - %-46s %s" % (h["title"][:46], h["score"]), file=sys.stderr)
assert hits, "search returned no hits"
first = hits[0]
for k in ("doc_id", "title", "url", "score", "chars"):
    assert first.get(k), "hit missing %s" % k
print(first["doc_id"])
' <<<"$PAYLOAD")"
echo "  doc_id: $DOC_ID"

say "tools/call get_doc (paginated)"
GETDOC="{\"jsonrpc\":\"2.0\",\"id\":4,\"method\":\"tools/call\",\"params\":{\"name\":\"get_doc\",\"arguments\":{\"doc_id\":\"$DOC_ID\",\"max_chars\":1200}}}"
rpc "$GETDOC" | payload | python3 -c '
import json, sys
d = json.load(sys.stdin)
print("  title:", d.get("title"))
print("  chars:", d.get("chars"), "| returned:", len(d.get("content") or ""))
print("  truncated:", d.get("truncated"), "| next_offset:", d.get("next_offset"))
assert "truncated" in d, "no truncation metadata"
assert d.get("next_offset"), "truncated reply has no next_offset"
assert d.get("url"), "reply has no source url"
'

say "tools/call find_in_doc"
FIND="{\"jsonrpc\":\"2.0\",\"id\":5,\"method\":\"tools/call\",\"params\":{\"name\":\"find_in_doc\",\"arguments\":{\"doc_id\":\"$DOC_ID\",\"query\":\"CAN\",\"limit\":2}}}"
rpc "$FIND" | payload | python3 -c '
import json, sys
d = json.load(sys.stdin)
hits = d.get("hits") or []
print("  hits:", d.get("count"))
for h in hits[:2]:
    print("  - offset=%-6s %s" % (h["offset"], (h.get("heading") or "")[:40]))
assert hits, "find_in_doc returned no hits for 'CAN'"
assert "chars" in d, "no chars field"
h = hits[0]
assert 0 <= h["offset"] < d["chars"], h
assert h.get("excerpt"), "hit has no excerpt"
'

say "tools/call list_spaces"
SPACES='{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"list_spaces","arguments":{}}}'
rpc "$SPACES" | payload | python3 -c '
import json, sys
d = json.load(sys.stdin)
sp = d.get("spaces") or []
print("  spaces: %d" % len(sp))
assert sp, "no public spaces"
'

say "tools/call list_docs"
LIST='{"jsonrpc":"2.0","id":7,"method":"tools/call","params":{"name":"list_docs","arguments":{"limit":3}}}'
rpc "$LIST" | payload | python3 -c '
import json, sys
d = json.load(sys.stdin)
docs = d.get("docs") or []
print("  docs:", len(docs), "| offset:", d.get("offset"))
assert docs, "list_docs returned nothing"
for x in docs:
    for k in ("doc_id", "title", "space", "url", "chars"):
        assert k in x, "doc entry missing %s" % k
'

say "negative: unknown doc_id must be isError"
# 业务失败必须是工具执行错误（isError=true），不能静默返回空内容
MISS='{"jsonrpc":"2.0","id":8,"method":"tools/call","params":{"name":"get_doc","arguments":{"doc_id":"no-such-doc"}}}'
RAW="$(curl -sS --max-time 30 -X POST "$EP" \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -H "Mcp-Session-Id: $SID" \
  -H "MCP-Protocol-Version: $PROTO" \
  -d "$MISS")"
python3 -c '
import json, sys
raw = sys.argv[1]
for line in raw.splitlines():
    line = line.strip()
    if line.startswith("data:"):
        line = line[5:].strip()
    if not line.startswith("{"):
        continue
    msg = json.loads(line)
    res = msg.get("result") or {}
    print("  isError:", res.get("isError"))
    assert res.get("isError") is True, "missing doc must set isError=true"
    break
else:
    sys.exit("no JSON-RPC frame for the negative case")
' "$RAW"

say "PASS — endpoint serves 5 tools, locates passages, paginates, exposes source URLs, and errors loudly"
