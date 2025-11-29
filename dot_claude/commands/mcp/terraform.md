---
description: Terraform MCPサーバーをプロジェクトに追加します
allowed-tools: Read, Edit, Write, Bash(mkdir:*), AskUserQuestion
---

Terraform MCPサーバーをプロジェクトに追加してください。

## 追加するサーバー

### 認証不要（.mcp.jsonに追加）

- **terraform**: Terraform Registry（プロバイダー、モジュール、ポリシー検索）

```json
{
  "terraform": {
    "command": "npx",
    "args": ["-y", "terraform-mcp-server"]
  }
}
```

### 認証必要（ユーザーに確認後、.claude/.mcp.jsonに追加）

- **terraform-cloud**: HCP Terraform/Enterprise操作（TFE_TOKENが必要）

```json
{
  "terraform-cloud": {
    "command": "npx",
    "args": ["-y", "terraform-mcp-server"],
    "env": {
      "TFE_TOKEN": "${TFE_TOKEN}",
      "TFE_HOSTNAME": "${TFE_HOSTNAME:-app.terraform.io}"
    }
  }
}
```

## 実行手順

1. `.mcp.json`を読み込み（なければ空オブジェクトで初期化）
2. `terraform`を`.mcp.json`に追加
3. ユーザーに認証必要なサーバー追加を確認
4. 追加する場合:
   - `.claude/`ディレクトリを作成
   - `.claude/.mcp.json`に`terraform-cloud`を追加
   - `.gitignore`に`.claude/.mcp.json`を追加（なければ）
5. 変更内容を報告し、Claude Code再起動を案内
