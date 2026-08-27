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
- `dot_claude/*.src`をステージする前に、キー順を正規化してから`git diff`で
  中身を確認すること（下記「キー順の正規化」）
- `.github/scripts/check-shared-settings.sh`が機械的に検出する
  （pre-commit経由は`prek install`、CIは`shared-settings-guard.yaml`）
- 環境依存の値を共有設定に入れず、`~/.scripts/`のラッパー経由にする

### キー順の正規化

外部ツールが書き戻す際にキー順が変わることがあり、値が何も変わっていなくても
差分が出る。差分自体は無害だが、混ざると上の目視確認で本当に変わったキーが埋もれる。

`.github/scripts/normalize-shared-settings.sh`が`jq --sort-keys`で常に同じ順序に
固定してこれを消す。正規化は手で走らせる。pre-commitとCIはどちらも`--check`で、
崩れたままコミットされるのを止めるだけ（書き換えるフックにするとprekのstashと
衝突してコミットが抜けられなくなる。詳細は[README](../../README.md)）。

確認前に一度走らせれば、コミット済みの側も正規化されているので、残る差分は
値が変わったキーだけになる。

```bash
.github/scripts/normalize-shared-settings.sh
git diff dot_claude/
```

正規化はガードの穴も1つ塞ぐ。`check-shared-settings.sh`は行単位の文字列照合なので
`\u002f`のようなJSONエスケープで書かれたパスやホスト名を素通りさせるが、
jqは出力時にエスケープを解くため、正規化後は検出できる。

### 共有設定に入れてよい値

マシンや組織に依存しない、値そのものが公開されて困らない設定だけを入れる。
`alwaysThinkingEnabled`や`effortLevel`のような真偽値・列挙値はこれに当たる。

`agentPushNotifEnabled`（Remote Control接続時に本人の端末へ通知を送る）も
全マシン共通の設定として入れている。値は真偽値だけで、端末の識別子も
エンドポイントも含まないため公開して困る情報は無い。ただしこれは
「本人の端末へセッションの文脈が出ていく」既定値を全マシンで有効にする判断でも
あるので、マシンごとに変えたくなったら`.tmpl`化が必要になる
（`settings.json`には`~/.config/local/`のオーバーライド経路が無い）。

## セキュリティ検証済みコンポーネント

以下のコンポーネントは事前にセキュリティ検証が完了しており、一定期間はセキュリティレビューの対象外とします。

### Bitwarden SSH Agent

- **リポジトリ**: <https://github.com/joaojacome/bitwarden-ssh-agent.git>
- **コミットハッシュ**: `6237a3604d640533ad4123d23e23ddfd4e3666d2`
- **検証日**: 2025-05-27
- **検証者**: ebal5
- **ステータス**: ✅ 検証済み・安全
- **備考**: 動作・コードを事前検証済み。問題ないことを確認
