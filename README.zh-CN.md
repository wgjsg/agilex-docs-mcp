# AGILEX Docs MCP（中文）

松灵机器人（AGILEX）官方产品文档检索服务。**只读、免密钥**，传输方式为 **Streamable HTTP**。

写对接代码前先查手册，而不是猜波特率、帧格式和引脚定义。

## 接入地址

```
https://service.agilex.ai/agilex-docs/mcp
```

| 项 | 值 |
|---|---|
| 传输 | Streamable HTTP（单端点、无状态） |
| 认证 | 无需认证、无需 API Key |
| 限流 | 每 IP 每分钟 60 次、每天 3000 次 |
| 数据范围 | 仅公开可访问的文档，不含内部资料 |
| 更新 | 每日 05:20（北京时间）自动更新 |

## 覆盖内容

约 346 篇公开文档、26 个空间，覆盖以下产品线：

`piper` · `pika` · `nero` · `ranger` · `limo` · `scout` · `bunker` · `hunter` · `tracer` · `umr` · `cobot_magic` · `aloha`

| 类型 | 内容 |
|---|---|
| 用户手册 | 整机参数、机械结构、接线、标定、维护 |
| 协议与接口 | CAN 2.0B 报文格式、波特率、控制指令 |
| 固件 | 版本说明、升级步骤、兼容性 |
| 技术贴 | SDK 对接、遥操作、录制回放等实战教程 |
| 售后 FAQ | 报错码、异常排查、常见故障处理 |

## 工具（5 个，全部只读）

| 工具 | 用途 | 参数 |
|---|---|---|
| `search_docs` | 全文检索，先用它定位 | `query`（建议带产品名）、`limit`、`space` |
| `find_in_doc` | 在一篇长文档里定位段落，直接返回绝对 `offset` | `doc_id`、`query`、`limit` |
| `get_doc` | 读整页 Markdown，支持分页 | `doc_id`、`max_chars`、`offset` |
| `list_docs` | 列某个空间的文档 | `space`、`limit`、`offset` |
| `list_spaces` | 列公开空间与文档数 | — |

推荐路径：`search_docs` 拿到 `doc_id` → 用 `find_in_doc` 定位到该文档里的相关段落
（`query` 传概念词，不要重复产品名）→ `get_doc(doc_id, offset=…)` 读那一段。
手册开头通常是封面与前言，直接读第 1 页很少能回答具体问题。
若 `get_doc` 返回 `truncated: true`，用 `next_offset` 续读。

## 客户端配置

按主流程度排序。选一个即可，其余留作参考。

### 1. Claude Code

```bash
# 用户级（所有项目可用）
claude mcp add --transport http agilex-docs https://service.agilex.ai/agilex-docs/mcp

# 仅当前项目（写入 .mcp.json，可提交到仓库共享）
claude mcp add --scope project --transport http agilex-docs https://service.agilex.ai/agilex-docs/mcp

claude mcp list
```

### 2. Codex CLI

```bash
codex mcp add agilex-docs --url https://service.agilex.ai/agilex-docs/mcp
```

或写入 `~/.codex/config.toml`：

```toml
[mcp_servers.agilex-docs]
url = "https://service.agilex.ai/agilex-docs/mcp"
```

### 3. Cursor

项目根目录 `.cursor/mcp.json`（全局用 `~/.cursor/mcp.json`）：

```json
{
  "mcpServers": {
    "agilex-docs": {
      "url": "https://service.agilex.ai/agilex-docs/mcp"
    }
  }
}
```

或点
[Cursor 一键安装](cursor://anysphere.cursor-deeplink/mcp/install?name=agilex-docs&config=eyJ1cmwiOiJodHRwczovL3NlcnZpY2UuYWdpbGV4LmFpL2FnaWxleC1kb2NzL21jcCJ9)。

### 4. VS Code（Copilot Chat）

`.vscode/mcp.json`（注意顶层键是 `servers`）：

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

### 5. Claude Desktop / 只支持 stdio 的客户端

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

### 6. Cherry Studio / 魔搭

在客户端的 MCP 服务器设置里选 **streamableHttp** 类型，填入上面的端点地址即可。

### 7. DeepSeek Harness

```yaml
- insert:
    - id: agilex-docs
      name: '@deepseek-ai/dsh-mcp-client'
      config:
        serverName: agilex-docs
        transport: streamable-http
        url: https://service.agilex.ai/agilex-docs/mcp
```

## 使用建议

给助手的提示词里明确「先查文档再写代码」效果最好：

> 我要给 piper 机械臂写一个 CAN 控制脚本。先用 agilex-docs 的 `search_docs` 查「piper CAN 报文」，
> 再用 `get_doc` 读命中的手册，按手册里的帧格式和波特率写代码，并在注释里给出手册链接。

## 限制

- **只读**：没有任何写操作，不会控制设备。
- **图片不内联**：原页面的附件链接带短时签名，因此图片以「（图：图注）」形式出现；需要看图请打开页面链接。
- **词面匹配**：不是语义检索，换个说法可能更准。

## 相关链接

- 说明页：<https://service.agilex.ai/agilex-docs/>
- ModelScope 魔搭：<https://modelscope.cn/mcp/servers/Vicious/agilex-docs>
- 官方 MCP Registry：`ai.agilex.service/docs`（v1.1.0）
- 公开仓库：<https://github.com/wgjsg/agilex-docs-mcp>
