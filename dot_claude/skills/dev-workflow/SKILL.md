---
name: dev-workflow
description: |
  開発作業のフローを制御するオーケストレーションスキル。
  worktree内外どちらでも使用可能。
  実処理はsuperpowersや既存スキルに委譲し、フロー順序の制御と
  worktree安全制約に専念する。

  以下の状況で使用:
  - 作業を開始するとき（worktree内外問わず）
  - 「ワークフロー開始」「作業開始」「何から始める？」
  - EnterWorktree直後の最初のタスク着手時

  以下では使用しない:
  - 単純な質問や調査のみの場合
allowed-tools: Read, Glob, Grep, Skill, Bash(git branch:*), Bash(git worktree list:*), Bash(git log:*), Bash(git diff:*), Bash(git status:*)
---

# Dev Workflow

開発フローを制御するオーケストレーションスキル。
実処理は superpowers や既存スキルに委譲し、このスキルは
**フロー順序の制御**と**worktree 安全制約**に専念する。

## 依存スキル

このスキルは以下のスキル/プラグインに委譲する:

- `superpowers:brainstorming` / `superpowers:writing-plans` /
  `superpowers:executing-plans` / `superpowers:subagent-driven-development`
- `/grill-me`（カスタムスキル）
- `/commit-commands:commit-push-pr`（commit-commands プラグイン）
- `/handover`（カスタムスキル、任意）

## 環境検出

作業開始時に現在の環境を検出する。

- **worktree 内**: `.claude/worktrees/` 配下で作業中
- **メインリポジトリ**: worktree 外で直接作業中

<HARD-GATE>
worktree 内の場合、worktree を作成しない。
git worktree add や EnterWorktree を呼ばないこと。
superpowers:using-git-worktrees も呼ばないこと。
worktree は既に存在する前提で動作する。
</HARD-GATE>

worktree 内の場合、作業ディレクトリ（`pwd`）をプロジェクトルートとして
使い、親リポジトリのパスを参照しないこと。

## スコープ判定

作業開始時にスコープを判定し、適切なパスを選択する。

| 規模 | 目安 | パス |
| --- | --- | --- |
| 小 | 設定値修正、typo修正、エイリアス追加など1-2ファイルの軽微な変更 | **Light**: 会話内で合意→即実装 |
| 中 | 新ツールの設定追加、複数ファイルにまたがる変更、テンプレート分岐の追加 | **Standard**: brainstorm→plan→実装 |
| 大 | ツール管理方針の変更、ディレクトリ構成の見直し、新しいワークフロー導入 | **Full**: grill→brainstorm→plan→実装 |

判断の補足:
- ファイル数は参考値。既存設定への影響やテンプレート複雑度で判断する
- メインリポジトリで直接作業する場合は通常 Light か Standard
- 判断に迷ったらユーザーに確認する

## フロー概要

```text
[環境検出] → スコープ判定 → Grill → Brainstorm → Plan → Execute → Wrap-up
```

ユーザーが明示的にスキップを指示した場合は確認の上で次に進んでよい。

---

## Phase 0: Grill（アイデアの深堀り）— Full のみ

**目的**: brainstorming の前に、目的・前提・制約を徹底的に問い直す

- `/grill-me` スキルに委譲する
- ユーザーのアイデアや要件を批判的に掘り下げ、曖昧さや見落としを洗い出す
- Light/Standard パスでは省略する

### 出口条件

- 目的と制約が明確になり、brainstorming に進む準備ができている

---

## Phase 1: Brainstorming（設計）— Standard/Full

- `superpowers:brainstorming` スキルに委譲する
- **ただし**: worktree 内の場合、brainstorming の Phase 4
  （worktree 作成）は**スキップすること**。worktree は既に存在する
- Light パスでは省略し、会話内で合意を得て Phase 3 に直接進む

### 出口条件

- 実装対象と成功基準が明確
- Full: ユーザー承認済みの設計ドキュメントが存在する
- Standard: 会話内でユーザー合意が得られている

---

## Phase 2: Planning（実装計画）— Standard/Full

- `superpowers:writing-plans` スキルに委譲する
- Light パスでは省略し、Phase 3 に直接進む

### 検証サイクルの補足

superpowers の計画テンプレートは TDD サイクルを前提とするが、
プロジェクトにテストフレームワークがない場合（dotfiles 等）は
以下の検証手段で代替する:

- シェルスクリプト: `shellcheck` + `shfmt` で静的解析
- テンプレート: `chezmoi execute-template` で展開確認
- 設定ファイル: `chezmoi diff` で差分確認
- Markdown: `markdownlint-cli2` でリント

### 出口条件

- ユーザー承認済みの実装計画が存在する

---

## Phase 3: Execution（実装）

- 原則 `superpowers:subagent-driven-development` に委譲する
- 1ファイルで完結する単純な変更の場合は
  `superpowers:executing-plans` でそのまま実行してよい
- Light パスでは計画なしで直接実装。検証は忘れずに行う
- ブロッカーに当たったら推測せず質問する

### 出口条件

- 計画の全ステップ完了（Light は合意内容の完了）
- 検証（lint/テスト）全通過

---

## Phase 4: Wrap-up（完了処理）

1. **最終検証**: `/lint:all` または個別の lint コマンドで検証 +
   `git diff` で意図しない変更がないか確認
2. **コミット・PR**: `/commit-commands:commit-push-pr` で作成
3. **引き継ぎ記録**（長期作業の場合、任意）: `/handover` で記録
4. **worktree 掃除**（worktree 内の場合のみ）:
   `git worktree list` で prunable があれば報告

### 出口条件

- 検証全通過
- コミットまたはPR作成済み

---

## Gotchas

- **worktree の二重作成禁止**: worktree 内の場合、
  `git worktree add` や `superpowers:using-git-worktrees` を
  絶対に呼ばないこと。brainstorming の Phase 4 もスキップすること
- **作業ディレクトリの固定**: worktree 内の場合、`pwd` が
  プロジェクトルート。親リポジトリを参照しないこと
- **Phase 0-2 での実装着手禁止**: grill/brainstorming/planning 段階で
  コード変更を始めないこと
- **依存プラグイン**: superpowers と commit-commands プラグインが
  有効であること
