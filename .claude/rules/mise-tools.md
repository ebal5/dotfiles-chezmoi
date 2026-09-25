---
paths: "**/*mise*", .tool-versions, scripts/setup-ubuntu.sh
description: mise（ツールバージョン管理）
---

# mise（ツールバージョン管理）

このリポジトリでmiseが受け持つのは、プロジェクトごとにバージョンを固定する必要が
あるツール（Node.js、Python等のランタイム、shellcheck、shfmt、terraform等）。
Nixとの使い分けは[CLAUDE.md](../../CLAUDE.md)の「ツール管理方針」を参照。

- miseの導入とグローバルのNode.js/Pythonは`scripts/setup-ubuntu.sh`が入れる
- terraformのようにPJごとに版が違うツールは、グローバルの
  `~/.config/mise/config.toml`ではなく各プロジェクトの`mise.toml`に書く
