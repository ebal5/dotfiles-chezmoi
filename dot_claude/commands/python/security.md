---
description: banditでPythonコードのセキュリティスキャンを実行します
allowed-tools: Bash(bandit:*), Bash(uv run bandit:*), Bash(uvx bandit:*)
argument-hint: [スキャン対象ディレクトリ（デフォルト: src/）]
---

banditでセキュリティスキャンを実行してください。

## 実行手順

1. 対象ディレクトリを決定：
   - 引数が指定されていればそれを使用
   - なければ `src/` をスキャン（存在しなければ `.`）
2. `uv run bandit -r <対象>` を実行
3. 結果を分析し、脆弱性を深刻度別に報告
4. 各脆弱性の修正方法を提案

## 深刻度の説明

- **HIGH**: 即座に修正が必要
- **MEDIUM**: 可能な限り修正すべき
- **LOW**: 検討が必要だが、許容できる場合もある

## 前提条件

- banditがインストールされていること
- `uv add bandit --dev` でインストール可能
