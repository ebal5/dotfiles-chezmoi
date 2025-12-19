---
description: プロジェクトにAWS読み取り系コマンドの許可を追加します
allowed-tools: Read, Edit, Write, Bash(mkdir:*)
---

プロジェクトの `.claude/settings.local.json` に AWS 読み取り系コマンドの許可を追加してください。

## 追加するコマンド

以下のAWS CLI読み取りコマンドを `permissions.allow` に追加:

```text
Bash(aws ecs describe-clusters:*)
Bash(aws ecs describe-services:*)
Bash(aws ecs describe-tasks:*)
Bash(aws ecs describe-task-definition:*)
Bash(aws ecs list-clusters:*)
Bash(aws ecs list-services:*)
Bash(aws ecs list-tasks:*)
Bash(aws ecs list-task-definitions:*)
Bash(aws logs describe-log-groups:*)
Bash(aws logs describe-log-streams:*)
Bash(aws logs get-log-events:*)
Bash(aws logs filter-log-events:*)
Bash(aws s3 ls:*)
Bash(aws sts get-caller-identity:*)
```

## 実行手順

1. `.claude/settings.local.json` を読み込み（なければ作成）
2. `permissions.allow` 配列に上記コマンドを追加（重複チェック）
3. 変更内容を報告
