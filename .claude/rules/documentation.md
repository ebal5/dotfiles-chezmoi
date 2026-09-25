---
paths: "**/*.md"
description: ドキュメント作成ガイドライン
---

# ドキュメント作成ガイドライン

## Markdownスタイル

markdownlintの既定ルール（MD031、MD040等）はPostToolUseフックが検出するため、
ここにはこのリポジトリ固有の設定だけを書く。

- **MD060**: テーブルは**compact style**（最小パディング）。CJK文字を含むテーブルでは
  aligned styleが文字幅の違いで破綻するため。`.markdownlint-cli2.yaml`で
  `style: compact`を明示している（既定の`consistent`はファイル内で揃っていれば
  aligned styleも通してしまう）。区切り行のダッシュ長（`| ------ |`）はMD060の
  対象外で誰も検出しないが、表示上は無害なので許容する。
  MD060の挙動がバージョン依存になるため、markdownlint-cli2はバージョンを固定している。
  固定箇所は`dot_config/shim-definitions`の1行だけで、CIもそこから抽出して使う
  （[CLAUDE.md](../../CLAUDE.md)の「ツール管理方針」を参照）

  compact styleの例:

  | 列1 | 列2 | 列3 |
  | --- | --- | --- |
  | データ | データ | データ |

## 編集後のlint実行

PostToolUseフック（`.claude/hooks/lint-edited-file.sh`）が編集後に
markdownlint-cli2を実行して指摘を返すため、手動実行は不要。

全ファイルに対して実行する場合は `/lint:all` コマンドを使用。
