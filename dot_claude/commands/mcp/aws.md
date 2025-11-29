---
description: AWS MCPサーバーをプロジェクトに追加します
allowed-tools: Read, Edit, Write, Bash(mkdir:*), AskUserQuestion
---

AWS MCPサーバーをプロジェクトに追加してください。

## 追加するサーバー

### 認証不要（.mcp.jsonに追加）

- **aws-knowledge**: AWSドキュメント、コードサンプル、リージョン情報

```json
{
  "aws-knowledge": {
    "type": "http",
    "url": "https://knowledge-mcp.global.api.aws"
  }
}
```

### 認証必要（ユーザーに確認後、.claude/.mcp.jsonに追加）

- **aws-api**: AWS CLI操作（AWS認証情報が必要）

```json
{
  "aws-api": {
    "command": "uvx",
    "args": ["awslabs.aws-api-mcp-server@latest"],
    "env": {
      "AWS_PROFILE": "${AWS_PROFILE:-default}"
    }
  }
}
```

## 実行手順

1. `.mcp.json`を読み込み（なければ空オブジェクトで初期化）
2. `aws-knowledge`を`.mcp.json`に追加
3. ユーザーに認証必要なサーバー追加を確認
4. 追加する場合:
   - `.claude/`ディレクトリを作成
   - `.claude/.mcp.json`に`aws-api`を追加
   - `.gitignore`に`.claude/.mcp.json`を追加（なければ）
5. 変更内容を報告し、Claude Code再起動を案内
