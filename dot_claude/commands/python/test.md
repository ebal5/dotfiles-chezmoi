---
description: pytestでPythonテストを実行します（uv環境）
allowed-tools: Bash
argument-hint: [テストパス（オプション）]
---

pytestでテストを実行してください。

## 実行手順

1. `uv run pytest $ARGUMENTS -v` を実行（引数がなければ全テスト）
2. テスト結果を分析
3. 失敗したテストがあれば、原因を説明し修正方法を提案

## 使用例

- `/python:test` - 全テスト実行
- `/python:test tests/` - testsディレクトリ以下を実行
- `/python:test -k "test_name"` - 特定のテストのみ
- `/python:test --cov=src` - カバレッジ付き（pytest-cov必要）

## 前提条件

- pytestがインストールされていること
- テストファイルは `test_*.py` または `*_test.py` の命名規則
