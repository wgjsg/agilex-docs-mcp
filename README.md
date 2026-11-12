# AGILEX Docs MCP

[![MCP](https://img.shields.io/badge/MCP-streamable--http-blue)](https://modelcontextprotocol.io)
[![Registry](https://img.shields.io/badge/registry-ai.agilex.service%2Fdocs-green)](https://registry.modelcontextprotocol.io/v0.1/servers?search=agilex)
[![License](https://img.shields.io/badge/license-MIT-lightgrey)](LICENSE)
[![Auth](https://img.shields.io/badge/auth-none-brightgreen)](#rate-limits)

Official product documentation for **AgileX Robotics (松灵机器人)** — user manuals,
CAN 2.0B protocol references, firmware notes, SDK tech posts and after-sales FAQ for
`piper`, `pika`, `nero`, `ranger`, `limo`, `scout`, `bunker`, `hunter`, `tracer`,
`umr`, `cobot_magic` and `aloha`.

Point your AI coding assistant at this server **before** writing integration code
for AgileX hardware, so it consults the real manual instead of guessing baud rates,
frame formats or pinouts.

> **This repository documents the public interface.** It covers the endpoint,
> the tool signatures and every client configuration. The indexing service that
> backs it is operated by AgileX and is not part of this repository.

---

## Endpoint

| | |
|---|---|
| **MCP URL** | `https://service.agilex.ai/agilex-docs/mcp` |
| **Transport** | Streamable HTTP — single endpoint, stateless |
| **Protocol** | `2025-11-25` (also answers `2025-06-18`, `2025-03-26`, `2024-11-05`) |
| **Auth** | None. Read-only public docs, rate limited per IP |
| **Registry** | `ai.agilex.service/docs` |
| **Docs page** | <https://service.agilex.ai/agilex-docs/> |
| **Health** | <https://service.agilex.ai/agilex-docs/health> |

No API key, no OAuth, no local process. If your client speaks Streamable HTTP,
you only need the URL.

---

## Quick start

Clients are listed in order of how common they are. Pick one.

| # | Client | Setup |
|---|---|---|
| 1 | **Claude Code** | `claude mcp add --scope user --transport http agilex-docs https://service.agilex.ai/agilex-docs/mcp` |
| 2 | **Codex CLI** | `codex mcp add agilex-docs --url https://service.agilex.ai/agilex-docs/mcp` |
| 3 | **Cursor** | [one-click install](cursor://anysphere.cursor-deeplink/mcp/install?name=agilex-docs&config=eyJ1cmwiOiJodHRwczovL3NlcnZpY2UuYWdpbGV4LmFpL2FnaWxleC1kb2NzL21jcCJ9), or the JSON below |
| 4 | **VS Code / Copilot** | `Ctrl+Shift+P` → `MCP: Add Server` → HTTP → paste the URL |
| 5 | Anything stdio-only | `npx -y mcp-remote https://service.agilex.ai/agilex-docs/mcp` |

```bash
# 1) Claude Code — all projects
claude mcp add --scope user --transport http agilex-docs https://service.agilex.ai/agilex-docs/mcp

# 2) Codex CLI — writes ~/.codex/config.toml
codex mcp add agilex-docs --url https://service.agilex.ai/agilex-docs/mcp
```

Cursor one-click:

```
cursor://anysphere.cursor-deeplink/mcp/install?name=agilex-docs&config=eyJ1cmwiOiJodHRwczovL3NlcnZpY2UuYWdpbGV4LmFpL2FnaWxleC1kb2NzL21jcCJ9
```

Any client that reads `mcpServers` (Cursor, Claude Desktop, Cline, Windsurf,
Cherry Studio, Continue, Zed, LibreChat, Dify …):

```json
{
  "mcpServers": {
    "agilex-docs": {
      "url": "https://service.agilex.ai/agilex-docs/mcp"
    }
  }
}
```

Full per-client instructions: [docs/CLIENTS.md](docs/CLIENTS.md).

---

## Tools

Five read-only tools. The names are deliberately `verb_noun` so a model can pick
the right one without reading the schema first.

| Tool | Purpose | Parameters |
|---|---|---|
| `search_docs` | Full-text search. **Start here.** Locate before reading. | `query` (include the product name), `limit` (1–25, default 8), `space` (optional) |
| `find_in_doc` | Locate a passage inside one long manual; returns absolute `offset` | `doc_id`, `query`, `limit` (1–10, default 5) |
| `get_doc` | Read one page as Markdown, paginated | `doc_id`, `max_chars` (default 20 000, honoured as requested, max 120 000), `offset` |
| `list_docs` | Inventory of a single space | `space` (optional), `limit` (1–300, default 100), `offset` (≥0) |
| `list_spaces` | All public spaces with page counts | — |

`search_docs` returns `doc_id`, `title`, `space`, `url`, `score`, `chars` and a
snippet. Then use `find_in_doc` to jump to the passage you need and read it with
`get_doc(doc_id, offset=…)`. If the response has `truncated: true`, call
`get_doc` again with `next_offset`.

Manuals open with a cover page and preface, so reading from offset 0 rarely
answers a specific question — that is why the search-then-locate-then-read path
is the recommended one rather than `get_doc` alone.

`max_chars` is honoured as requested (1–120 000), and the applied value is echoed
back as `max_chars` in the response. There used to be an undocumented 2000-character
floor; a caller paging in 1000-character steps would then re-read overlapping text
without any indication, so it was removed.

### Field semantics

`count` means different things in different tools, deliberately:

| Tool | `count` | Also returned |
|---|---|---|
| `search_docs` | number of results in this reply | `results[]` |
| `list_docs` | number of docs in this page | `offset`, `docs[]` (no total — use `list_spaces`) |
| `find_in_doc` | **total passages matched** | `returned`, `matched_terms`, `missing_terms` |

`find_in_doc(limit=1)` can therefore return `count: 24` with one hit — `returned`
tells you what is in the array. `matched_terms` / `missing_terms` make partial
matches explicit instead of silently ignoring words the page does not contain.

Numeric parameters declare their bounds in the schema: `limit` 1–25 (search),
1–10 (find_in_doc), 1–300 (list_docs); `max_chars` 1–120000; `offset` ≥ 0.
An out-of-range value is a validation error, not a silent clamp.

A result whose title carries a `【未发】` / `【暂不对外】` marker is still
searchable — whether it is published is the documentation owner's call, and the
code does not blacklist by keyword — but the entry carries `status_note` so a
model does not cite unreleased material as settled.

### Why `find_in_doc` exists

13% of the corpus needs pagination and the longest page is 162 000 characters;
locating one CAN frame table in that by paging with `get_doc` costs nine round
trips. `find_in_doc` scores paragraphs and returns their absolute offsets, so a
single `get_doc(doc_id, offset=…)` lands on the table.

Pass the *concept* as `query`, not the product name. Terms that already appear in
the page title are ignored: `search_docs` picked the page by them, so repeating
them only dilutes the ranking. This is measurable — on the RANGER MINI 3.0 manual,
`query="RANGER MINI 3.0 CAN 波特率"` returned 44 passages with "1.1 产品列表" on
top, while `query="CAN 波特率"` returned 2 with "3.2 CAN接口协议" on top.

Scoring is weighted by corpus-wide document frequency, not raw term count: `can`
appears in 138 pages (weight 1.25) while `波特率` appears in 39
(weight 2.29). If the query contains a distinctive term that the page does not
contain, the tool returns zero hits and says so — otherwise English manuals
produced 76 meaningless `can` matches for the query "CAN 波特率". A query made
only of generic terms (e.g. just `CAN`) still returns matches.

### Response shape

```jsonc
// search_docs("piper CAN 波特率")
{
  "query": "piper CAN 波特率",
  "count": 3,
  "results": [
    {
      "doc_id": "01a06659-2d4e-7029-bc64-63f9352b34a6",
      "title": "PIPER X 用户手册(CN)",
      "space": "AGX-机械臂产品手册",
      "url": "https://kb.agilex.ai/s/agx-robot-arm-products-cn-en/p/pWVjLJsYc0",
      "score": 18.42,
      "chars": 13264,
      "snippet": "...CAN通信标准采用的是CAN2.0B标准，通讯波特率为1000K..."
    }
  ]
}
```

```jsonc
// get_doc(doc_id="01a06659-…", max_chars=2000)
{
  "doc_id": "01a06659-2d4e-7029-bc64-63f9352b34a6",
  "title": "PIPER X 用户手册(CN)",
  "url": "https://kb.agilex.ai/s/agx-robot-arm-products-cn-en/p/pWVjLJsYc0",
  "chars": 13264,
  "offset": 0,
  "truncated": true,
  "next_offset": 2000,
  "content": "..."
}
```

```jsonc
// find_in_doc(doc_id="01a06659-…", query="波特率")
{
  "doc_id": "01a06659-2d4e-7029-bc64-63f9352b34a6",
  "title": "PIPER X 用户手册(CN)",
  "url": "https://kb.agilex.ai/s/agx-robot-arm-products-cn-en/p/pWVjLJsYc0",
  "chars": 13264,
  "query": "波特率",
  "count": 1,
  "hits": [
    {
      "offset": 12101,                // ← feed straight into get_doc
      "heading": "6 机械臂CAN协议",
      "score": 45.85,
      "matched": ["波特", "特率"],
      "excerpt": "…通讯波特率为1000K，报文格式采用MOTOROLA(MSB)格式…"
    }
  ],
  "hint": "用 get_doc(doc_id, offset=hit.offset) 读这一段前后；offset 是全文绝对位置。"
}
```

`url` always points at the original page — cite it so the user can verify.

---

## Client configuration

<details open>
<summary><b>Claude Code</b></summary>

```bash
# all projects
claude mcp add --scope user --transport http agilex-docs https://service.agilex.ai/agilex-docs/mcp

# this project only (writes .mcp.json, can be committed)
claude mcp add --scope project --transport http agilex-docs https://service.agilex.ai/agilex-docs/mcp

claude mcp list
```
</details>

<details>
<summary><b>Codex CLI</b></summary>

```bash
codex mcp add agilex-docs --url https://service.agilex.ai/agilex-docs/mcp
```

or `~/.codex/config.toml`:

```toml
[mcp_servers.agilex-docs]
url = "https://service.agilex.ai/agilex-docs/mcp"
```

Inside Codex, `/mcp` lists active servers. Codex uses the server's `instructions`
field as global guidance, so the search-then-read workflow is already in place.
</details>

<details>
<summary><b>Cursor</b></summary>

`.cursor/mcp.json` in the project, or `~/.cursor/mcp.json` globally:

```json
{
  "mcpServers": {
    "agilex-docs": {
      "url": "https://service.agilex.ai/agilex-docs/mcp"
    }
  }
}
```

Reload the window (`Ctrl+Shift+P` → Reload Window). Settings → MCP should list
`agilex-docs` with 5 tools.
</details>

<details>
<summary><b>VS Code / Copilot</b></summary>

`.vscode/mcp.json` — note the top-level key here is `servers`, not `mcpServers`:

```json
{
  "servers": {
    "agilex-docs": {
      "type": "http",
      "url": "https://service.agilex.ai/agilex-docs/mcp"
    }
  }
}
```

Or `Ctrl+Shift+P` → **MCP: Add Server** → HTTP → paste the URL.
</details>

<details>
<summary><b>Claude Desktop (stdio bridge)</b></summary>

Claude Desktop only speaks stdio, so bridge the endpoint with `mcp-remote`:

```json
{
  "mcpServers": {
    "agilex-docs": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://service.agilex.ai/agilex-docs/mcp"]
    }
  }
}
```

Quit and reopen the app completely after saving.
</details>

<details>
<summary><b>Cherry Studio</b></summary>

Settings → MCP Servers → Add → type `streamableHttp`, URL as above.
Cherry Studio also accepts the `mcpServers` JSON directly.
</details>

<details>
<summary><b>DeepSeek Harness (DSH)</b></summary>

DSH connects through `@deepseek-ai/dsh-mcp-client`, configured as a Cordis overlay:

```yaml
- insert:
    - id: agilex-docs
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        serverName: agilex-docs
        transport: streamable-http
        url: https://service.agilex.ai/agilex-docs/mcp
```

```bash
dsh web --patch "$PWD/examples/agilex-docs.cordis.yml"
```

Tools appear as `mcp__agilex-docs__search_docs`.
</details>

<details>
<summary><b>ChatGPT custom connector</b></summary>

Paid plan, web only: Settings → Connectors → Advanced → enable Developer mode →
Create → URL above, authentication **No authentication**.
</details>

---

## Example prompts

> I need a CAN control script for the piper arm. First call `search_docs` with
> "piper CAN 报文", then `get_doc` on the best hit, and write the code using the
> frame format and baud rate from the manual. Cite the manual URL in a comment.

> Our ranger mini throws a chassis error code. Search the after-sales FAQ for the
> code, quote the troubleshooting steps and link the page.

Because the server ships an `instructions` block telling the model to search first
and cite URLs, the workflow usually happens without any extra prompting.

---

## Scope and data

The corpus covers product documentation that is publicly accessible at
<https://kb.agilex.ai>. Internal spaces are excluded: the service reads only
publicly shared content and never authenticates, so internal documents cannot be
reached through this endpoint.

MCP access therefore does not depend on the visitor login on the knowledge base.
Search and reading work anonymously; only the human-facing page `url` redirects
to a visitor login (that gate exists for access logging, not authorization).

When a query names a product (`pika 固件升级`, `ranger CAN 波特率`), results are
restricted to that product's documents. If the product has not documented the
topic, the reply is an empty result set with a hint saying so — it never falls
back to another product's manual. Cross-product fallback is the dangerous
failure mode here: a user could follow PiPER flashing steps on a PIKA.

| | |
|---|---|
| Documents | **655** (identical, space by space, to the "文档 N" counters a logged-in visitor sees) |
| Pages with content | **619** |
| Of those, ≥500 chars of prose | 498 (`substantial` in `/health`; a length statistic, not a content check) |
| Container / empty entries | 36 (excluded from search) |
| Group nodes (📁) | 121 (folder-only, not counted as documents — same rule as the KB UI) |
| Spaces | **35** |
| Characters | ~3.6 M |
| Refresh | daily 05:20 Asia/Shanghai |
| Languages | Chinese and English |

The knowledge base also contains **folder pages and placeholder pages with no body
text**. These are excluded from search results: a folder titled "PIKA固件升级" would
otherwise outrank real content for that query and return an empty page. They remain
listable through `list_docs`, and `get_doc` on one returns `empty: true` with a hint
rather than 0 characters.

New public spaces are added automatically; withdrawn shares are removed on the
next refresh. The nightly job also diffs the index against the spaces a logged-in
visitor can read and fails loudly (`missing_shares` in `snapshot.json`) when a
space is readable but not shared — that drift is how eight spaces / 137 pages went
missing until the 2026-11-11 audit.

---

## Rate limits

| Scope | Limit |
|---|---|
| Per IP, per minute | 60 requests |
| Per IP, per day | 3 000 requests |
| Over limit | HTTP `429` + `Retry-After` |

Higher quota or a dedicated endpoint: contact AgileX (see [Feedback](#feedback)).

---

## Limits

- **Read-only.** No write tools; nothing here can move a robot.
- **Images are not inlined.** Attachment URLs on the source pages are signed with a
  short TTL, so images render as `（图：caption）`; open the page `url` to view them.
- **Binary attachments** (PDF/XLSX) in public spaces are not parsed — page bodies only.
- **Lexical matching**, not semantic. Rephrase if a term misses.
- **One product family per query** works best; cross-product questions need
  multiple searches.

---

## Verify it works

```bash
# health
curl -s https://service.agilex.ai/agilex-docs/health | jq

# MCP handshake — the reply is text/event-stream, so strip the "data: " prefix
# before piping to jq (piping SSE straight into jq fails with a parse error)
curl -s -X POST https://service.agilex.ai/agilex-docs/mcp \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json, text/event-stream' \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"curl","version":"1"}}}' \
  | sed -n 's/^data: //p' | jq '.result.serverInfo'

# full round trip (initialize → tools/list → search → find_in_doc → get_doc)
./scripts/smoke-test.sh

# the Chinese README as plain text (same source as README.zh-CN.md)
curl -s https://service.agilex.ai/agilex-docs/readme.md | head
```

---

## Repository layout

```
README.md                    this file
README.zh-CN.md              Chinese version; also served at /agilex-docs/readme.md
server.json                  official MCP Registry manifest
LICENSE                      MIT (documentation + manifest)
docs/CLIENTS.md              per-client setup, long form
examples/                    copy-paste configs per client
scripts/smoke-test.sh        end-to-end check against the live endpoint
```

---

## Where to find it

| Directory | Entry | Link |
|---|---|---|
| **ModelScope 魔搭** | Chinese listing, Cursor one-click install | <https://modelscope.cn/mcp/servers/Vicious/agilex-docs> |
| **Official MCP Registry** | `ai.agilex.service/docs` v1.5.0 | <https://registry.modelcontextprotocol.io/?q=agilex> |
| **Glama** | TDQS **A (4.3/5)** | <https://glama.ai/mcp/connectors/ai.agilex.service/docs> |
| **GitHub** | this repository, MIT | <https://github.com/wgjsg/agilex-docs-mcp> |

Search term inside any directory: `agilex`.

The endpoint is fixed, so no directory listing is required to use it.

## Usage statistics

Live call statistics for this service: <https://service.agilex.ai/agilex-docs/stats>

The console is **invite-only** — email and password, no guest access. Any member
can invite others from the Members page; the invitation email carries a
single-use link to set a password.

Trends, per-tool share, most-read documents, and a filtered call log. The
"query / intent" column is the tool argument the server actually received —
MCP does not transport the user's message, so it is not the user's own words.
A caller that wants its wording recorded can send `X-MCP-Query`; it lands in
the CSV export rather than the table.

---

## Feedback

Missing or wrong document → contact AgileX support through
<https://www.agilex.ai/> and include the page URL.

Issues about **this repository** (manifest, docs, client configs) → open an issue here.
Issues about **document content** → the support channel, since the docs live in the
internal knowledge base and this repo cannot edit them.

---

## License

MIT — see [LICENSE](LICENSE). The license covers the documentation and manifest in
this repository. The documentation content served over MCP remains the property of
AgileX Robotics.
