---
description: ruffでPythonコードのlint/formatを実行します（uv環境）
allowed-tools: Bash(ruff:*), Bash(uv run ruff:*), Bash(uvx ruff:*)
---

Pythonコードのlint/formatを実行してください。

## 実行手順

1. `ruff check --fix .` を実行してlintエラーを自動修正
2. `ruff format .` を実行してコードをフォーマット
3. 修正された箇所があれば報告
4. エラーが残っている場合は、修正方法を提案

## 前提条件

- ruffがインストールされていること
- uvを使用している場合は `uv run ruff` でも実行可能

## 設定ファイル

プロジェクトに `pyproject.toml` または `ruff.toml` があれば、その設定が使用されます。

## 注意事項

- **checkとformatは必ずセットで実行する**: `ruff check --fix`でインポート順序（I001）などを修正した後、`ruff format`も実行すること。checkだけでは括弧の配置などのフォーマットが更新されず、CIで失敗する原因になる
- **CIにpushする前にローカルで確認**: `ruff check . && ruff format --check .` を実行して両方パスすることを確認してからpushする
