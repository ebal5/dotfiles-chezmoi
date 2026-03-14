---
paths: dot_config/sh-like-aliases, dot_scripts/*fzf*
description: fzfユーティリティコマンド
---

# fzfユーティリティ

fzfベースのユーティリティコマンドは `dot_scripts/executable_fzf_utils.sh` で実装し、
`dot_config/sh-like-aliases` でエイリアス定義している。

## 修正時の注意

- 新しいfzfコマンドを追加する場合、実装は `dot_scripts/executable_fzf_utils.sh` に、
  エイリアスは `dot_config/sh-like-aliases` に追記すること
- 依存関係: `fzf`（必須）、`docker`/`git`（各コマンド用）、`ripgrep`/`fd`/`bat`（推奨）
- 詳細な使用方法のドキュメントは `FZF_UTILS.md` を更新すること
