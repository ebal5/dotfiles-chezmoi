---
description: プロジェクトのClaude Code設定を初期化します
allowed-tools: Read, Edit, Write, Bash(mkdir:*)
---

プロジェクトのClaude Code初期設定を行ってください。

## 実行内容

### 1. .gitignoreの設定

`.gitignore`に以下のClaude Code関連エントリを追加（既存なら確認のみ）:

```text
# Claude Code local settings
.claude/.mcp.json
.claude/settings.local.json
```

### 2. .claude/ディレクトリの作成

`.claude/`ディレクトリが存在しない場合は作成。

### 3. 推奨: CLAUDE.mdの作成確認

プロジェクトルートに`CLAUDE.md`がない場合、作成を提案。
内容は以下を参考に、プロジェクトに合わせて調整:

```markdown
# CLAUDE.md

このファイルは、Claude Code がこのプロジェクトで作業する際のガイダンスを提供します。

## プロジェクト概要

[プロジェクトの説明]

## 主要コマンド

- `[ビルドコマンド]`
- `[テストコマンド]`
- `[リントコマンド]`

## アーキテクチャ

[プロジェクト構造の説明]
```

## 実行手順

1. `.gitignore`を読み込み、Claude Code関連エントリの有無を確認
2. 不足しているエントリを追加
3. `.claude/`ディレクトリを作成（なければ）
4. `CLAUDE.md`の有無を確認し、なければ作成を提案
5. 完了報告
