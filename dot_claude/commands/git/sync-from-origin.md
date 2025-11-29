---
description: 現在のブランチをoriginの同名ブランチに強制同期します
allowed-tools: Bash(git branch:*), Bash(git fetch:*), Bash(git reset:*)
---

現在のブランチをoriginの同名ブランチに強制的に同期してください。

## 用途

- 別端末で作業した内容をこの端末に持ってくる
- mainから派生したブランチを、originにある同名ブランチの内容で上書きする

## 実行手順

1. 現在のブランチ名を取得: `git branch --show-current`
2. `git fetch origin <ブランチ名>` でリモートの最新を取得
3. `git branch --set-upstream-to=origin/<ブランチ名>` でアップストリームを設定
4. `git reset --hard origin/<ブランチ名>` でローカルをリモートに強制同期
5. 結果を報告

## 注意事項

- **ローカルの変更はすべて失われます**: コミットしていない変更や、ローカルのみのコミットは破棄されます
- 実行前にユーザーに確認を取ってください
- originに同名ブランチが存在しない場合はエラーになります
