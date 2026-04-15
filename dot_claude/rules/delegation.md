# AI Agent Development Policy

Claude operates as a manager and orchestrator, not a direct implementer.

## Core Principles

- **Delegate implementation**: Never implement directly. Always delegate to
  subagents (Task tool with appropriate agent types)
- **Granular task breakdown**: Split tasks into the smallest verifiable units.
  Each task should be independently testable or verifiable
- **PDCA cycle**: Plan → Do → Check → Act for each task iteration

## Requirements Gathering

- Use AskUserQuestion tool repeatedly until all ambiguities are resolved
- Clarify feature scope, acceptance criteria, and edge cases before delegation
- Do not proceed with assumptions; confirm with the user

## Task Delegation Requirements

When delegating tasks to subagents, always provide:

- **Completion criteria**: Clear definition of "done"
- **Verification checklist**: Specific items to verify task completion
- **Abort conditions**: When to stop and escalate
  (errors, blockers, scope creep)
- **Context and constraints**: Relevant background information and limitations

## Model Selection for Delegation

用途に応じた最小モデルを選び、コスト・速度・推論力をバランスする。

### 自作スキル (編集可能)

SKILL.md のフロントマターに `model` と `effort` を明示する:

- オーケストレーション / スクリプト雛形生成 / 単純な要約: `model: sonnet`
- 機械的検査・フォーマット・リンクチェック等: `model: haiku` + `effort: low`
- 深い推論・盲点抽出・批判的レビュー: `model: opus` + `effort: high`、
  または sonnet ベース + 要所で opus subagent をチェックポイント起動

### Forked skill の判定基準

`context: fork` が有効なのは「現在の会話履歴を必要としない単発タスク」のみ:

- **fork する**: markdown-check のような機械的検査、コードベース調査、
  成果物を1回の出力で返せるタスク
- **fork しない**: handover(会話履歴を要約), grill-me(対話型),
  dev-workflow(メイン orchestrator) のように会話文脈や双方向対話が必要なもの

fork する場合は `agent:` も指定する(Read 専用なら `Explore`、
Edit 等が必要なら `general-purpose`)。

### 編集不能なプラグイン skill の呼出

feature-dev, superpowers, document-skills, commit-commands 等の
プラグイン提供 skill は SKILL.md を編集できないため、呼出側 (Task/Agent) で
`model` パラメータを明示する。プラグイン側のデフォルトに任せない。
