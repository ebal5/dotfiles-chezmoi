---
description: セキュリティ検証済みコンポーネントと共有設定の取り扱い
---

# セキュリティ

## 共有設定の取り扱い

このリポジトリは**public**。そして`~/.claude/settings.json`と`~/.claude/.mcp.json`は
`dot_claude/*.src`へのシンボリックリンクなので、Claude Code自身やherdr等の
外部ツールが書き込んだ内容が、そのまま作業ツリーに現れる。

- 業務プロジェクトの組織名・リポジトリ名・社内ドメイン・ローカルパスが
  `autoMode`や`hooks`として書き込まれることが実際にあった
- `dot_claude/*.src`をステージする前に`git diff`で中身を確認すること
- `.github/scripts/check-shared-settings.sh`が機械的に検出する
  （pre-commit経由は`prek install`、CIは`shared-settings-guard.yaml`）
- 環境依存の値を共有設定に入れず、`~/.scripts/`のラッパー経由にする

## セキュリティ検証済みコンポーネント

以下のコンポーネントは事前にセキュリティ検証が完了しており、一定期間はセキュリティレビューの対象外とします。

### Bitwarden SSH Agent

- **リポジトリ**: <https://github.com/joaojacome/bitwarden-ssh-agent.git>
- **コミットハッシュ**: `6237a3604d640533ad4123d23e23ddfd4e3666d2`
- **検証日**: 2025-05-27
- **検証者**: ebal5
- **ステータス**: ✅ 検証済み・安全
- **備考**: 動作・コードを事前検証済み。問題ないことを確認
