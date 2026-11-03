# AGILEX Docs MCP

MCP server for **AgileX Robotics (松灵机器人)** product documentation — user manuals,
CAN/protocol references, firmware notes, tech posts and field-service FAQ for
piper, pika, nero, ranger, limo, scout, bunker, hunter, tracer, umr and cobot_magic.

Point your AI coding assistant at it before writing integration code for AgileX
hardware, so it consults the real manuals instead of guessing baud rates, frame
formats or pinouts.

| | |
|---|---|
| **MCP endpoint** | `https://service.agilex.ai/agilex-docs/mcp` |
| **Transport** | Streamable HTTP (single endpoint, stateless) |
| **Registry name** | `ai.agilex/docs` |
| **Auth** | None — read-only public docs, rate limited per IP |
| **Rate limit** | 60 requests/min, 3000/day per IP |
| **Usage dashboard** | <https://service.agilex.ai/agilex-docs/insights> |
| **Website** | <https://www.agilex.ai/> |

---

## Connect

### Cursor

One click:

```
cursor://anysphere.cursor-deeplink/mcp/install?name=agilex-docs&config=eyJ1cmwiOiJodHRwczovL3NlcnZpY2UuYWdpbGV4LmFpL2FnaWxleC1kb2NzL21jcCJ9
```

Or add to `.cursor/mcp.json` (project) / `~/.cursor/mcp.json` (global):

```json
{
  "mcpServers": {
    "agilex-docs": {
      "url": "https://service.agilex.ai/agilex-docs/mcp"
    }
  }
}
```

Then `Ctrl+Shift+P` → **Reload Window** if it does not appear under Settings → MCP.

### Claude Code

```bash
claude mcp add agilex-docs --transport http https://service.agilex.ai/agilex-docs/mcp
```

### Claude Desktop

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

### VS Code / Continue / any remote-MCP client

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

### ChatGPT

Requires a paid plan, web only: Settings → Security and login → enable Developer
mode → <https://chatgpt.com/plugins> → add a connector with the URL above and
authentication **None**.

---

## Tools

| Tool | Purpose | Parameters |
|---|---|---|
| `search_docs` | Full-text search. **Start here.** | `query` (include the product name), `limit` (1–25, default 8), `space` (optional) |
| `get_doc` | Read a page as Markdown, paginated | `doc_id`, `max_chars` (default 20000, max 120000), `offset` |
| `list_docs` | Inventory of a space | `space` (optional), `limit` (1–300), `offset` |
| `list_spaces` | Public spaces with page counts | — |

`search_docs` returns `doc_id`, `title`, `space`, `url`, `score`, `chars` and a
snippet. Pass `doc_id` to `get_doc`; if the reply has `truncated: true`, call
again with `next_offset` to continue.

Example:

```jsonc
// 1. locate
{"query": "piper CAN 波特率 报文格式", "limit": 3}

// 2. read (response excerpt)
{
  "doc_id": "01a06659-2d4e-7029-bc64-63f9352b34a6",
  "title": "PIPER X 用户手册(CN)",
  "url": "https://kb.agilex.ai/s/agx-robot-arm-products-cn-en/p/pWVjLJsYc0",
  "chars": 13264,
  "truncated": true,
  "next_offset": 2000,
  "content": "...CAN通信标准采用的是CAN2.0B标准，通讯波特率为1000K，报文格式采用MOTOROLA(MSB)格式..."
}
```

---

## Scope and data

The corpus is built from Document (Docmost) spaces that are marked
**「互联网所有人可访问」** — i.e. already public at <https://kb.agilex.ai>.
Spaces marked 内部 / 非对外 are **not** reachable: the crawler never authenticates,
it only uses Docmost's anonymous share endpoints, so internal content cannot leak
even through a bug.

Current snapshot: **346 pages / ~3.0M characters / 26 spaces**, refreshed daily at
05:20 Asia/Shanghai. New public spaces appear automatically; revoked ones drop out.

Docs are Chinese and English; searching in Chinese usually works best for
manuals published in Chinese.

---

## Limits

- **Read-only.** No write tools; nothing here can control a robot.
- **Images are not inlined.** Docmost serves attachments with short-lived signed
  URLs, so a snapshot would ship dead links. Images render as `（图：caption）`;
  open the page `url` to see them.
- **Binary attachments** (PDF/XLSX) inside public spaces are not parsed yet —
  page bodies only.
- **Lexical matching**, not semantic. Rephrase if a term misses.
- Registry entry is in **preview** status per the MCP registry's own notice.

---

## Feedback

Missing or wrong document → contact AgileX support through the usual channel
(<https://www.agilex.ai/>). Please include the page URL.

For higher rate limits or a dedicated endpoint, contact AgileX.
