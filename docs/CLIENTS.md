# Client setup

One endpoint for every client:

```
https://service.agilex.ai/agilex-docs/mcp
```

Streamable HTTP, single endpoint, stateless. No API key, no local process.
After connecting, the model should see five tools:
`search_docs` / `find_in_doc` / `get_doc` / `list_docs` / `list_spaces`.

Sections below are ordered by how common each client is — start at the top.

| # | Client | Fastest path |
|---|---|---|
| 1 | **Claude Code** | `claude mcp add --transport http agilex-docs https://service.agilex.ai/agilex-docs/mcp` |
| 2 | **Codex CLI** | `codex mcp add agilex-docs --url https://service.agilex.ai/agilex-docs/mcp` |
| 3 | **Cursor** | [one-click install](cursor://anysphere.cursor-deeplink/mcp/install?name=agilex-docs&config=eyJ1cmwiOiJodHRwczovL3NlcnZpY2UuYWdpbGV4LmFpL2FnaWxleC1kb2NzL21jcCJ9) |
| 4 | **VS Code / Copilot** | `Ctrl+Shift+P` → `MCP: Add Server` → HTTP → paste the URL |
| 5 | **Claude Desktop / Cline / anything stdio-only** | `npx -y mcp-remote https://service.agilex.ai/agilex-docs/mcp` |
| 6 | **Cherry Studio** | Settings → MCP Servers → `streamableHttp` |
| 7 | **DeepSeek Harness** | `dsh web --patch examples/agilex-docs.cordis.yml` |
| 8 | **ChatGPT** | custom connector, paid plan + web only |

---

## 1. Claude Code

```bash
# all projects
claude mcp add --transport http agilex-docs https://service.agilex.ai/agilex-docs/mcp

# this project only — writes .mcp.json, safe to commit and share
claude mcp add --scope project --transport http agilex-docs https://service.agilex.ai/agilex-docs/mcp

claude mcp list
claude mcp get agilex-docs
```

`.mcp.json` form:

```json
{
  "mcpServers": {
    "agilex-docs": {
      "type": "http",
      "url": "https://service.agilex.ai/agilex-docs/mcp"
    }
  }
}
```

---

## 2. Codex CLI / ChatGPT desktop

Codex stores MCP servers in `~/.codex/config.toml` (or a trusted project's
`.codex/config.toml`). The ChatGPT desktop app, Codex CLI and the IDE extension
share this file.

```bash
codex mcp add agilex-docs --url https://service.agilex.ai/agilex-docs/mcp
codex mcp list
```

```toml
[mcp_servers.agilex-docs]
url = "https://service.agilex.ai/agilex-docs/mcp"
```

`/mcp` inside Codex lists active servers. Codex reads the server's `instructions`
field as global guidance; ours already states "search first, then read, cite url".

---

## 3. Cursor

One click:

```
cursor://anysphere.cursor-deeplink/mcp/install?name=agilex-docs&config=eyJ1cmwiOiJodHRwczovL3NlcnZpY2UuYWdpbGV4LmFpL2FnaWxleC1kb2NzL21jcCJ9
```

Or `.cursor/mcp.json` (project) / `~/.cursor/mcp.json` (global):

```json
{
  "mcpServers": {
    "agilex-docs": {
      "url": "https://service.agilex.ai/agilex-docs/mcp"
    }
  }
}
```

Reload the window if the entry does not show up. Settings → MCP should list
`agilex-docs` with 5 tools. Tool namespace in agent mode is `user-agilex-docs`
(user config) or `project-0-<workspace>-agilex-docs` (project config).

---

## 4. VS Code (Copilot Chat)

`Ctrl+Shift+P` → **MCP: Add Server** → **HTTP** → paste the URL → ID `agilex-docs`
→ choose workspace or user scope.

Or `.vscode/mcp.json` — the top-level key is `servers` here, **not** `mcpServers`:

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

### Cline / Roo Code

MCP Servers → Remote Servers → Add:

| Field | Value |
|---|---|
| Name | `agilex-docs` |
| URL | `https://service.agilex.ai/agilex-docs/mcp` |
| Transport | `Streamable HTTP` |

### Continue

`~/.continue/config.yaml`:

```yaml
mcpServers:
  - name: agilex-docs
    type: streamable-http
    url: https://service.agilex.ai/agilex-docs/mcp
```

Continue's `type` values are `stdio`, `sse`, `streamable-http`.
MCP tools only work in agent mode.

---

## 5. Claude Desktop

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

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

Fully quit and reopen the app (closing the window is not enough). First launch
downloads `mcp-remote` through npx.

---

## 6. Cherry Studio

Settings → **MCP Servers** → Add → type **streamableHttp**:

| Field | Value |
|---|---|
| Name | `agilex-docs` |
| Type | `streamableHttp` |
| URL | `https://service.agilex.ai/agilex-docs/mcp` |

Pasting the `mcpServers` JSON also works — Cherry Studio imports it.

---

## 7. DeepSeek Harness

`examples/agilex-docs.cordis.yml`:

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

`serverName` must match `[A-Za-z0-9_-]{1,32}`. Tools are exposed as
`mcp__agilex-docs__search_docs`.

---

## 8. ChatGPT (custom connector)

Paid plan, web only:

Settings → **Connectors** → Advanced → enable **Developer mode** → Create:

| Field | Value |
|---|---|
| Name | `AGILEX Docs` |
| MCP Server URL | `https://service.agilex.ai/agilex-docs/mcp` |
| Authentication | `No authentication` |

---

## Anything else

If the client speaks Streamable HTTP, paste the URL. If it only speaks stdio,
wrap it:

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

Windsurf, Zed, Raycast, LibreChat and Dify all work this way.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Client shows 0 tools | URL saved but window not reloaded | Reload the window / restart the app |
| `421 Invalid Host header` | Ancient client sending a spoofed Host | Use the exact URL above |
| `429` | Per-IP quota | 60/min, 3000/day; wait for `Retry-After` |
| Search returns nothing | Lexical match miss | Add the product name, or try the English model name |
| Garbled Chinese in a stdio client | Locale not UTF-8 | Set `LANG=*.UTF-8` before launching |
