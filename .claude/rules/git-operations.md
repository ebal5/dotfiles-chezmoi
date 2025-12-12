---
paths: dot_gitconfig, **/.git/**, **/.github/**
description: Git操作ガイドラインとClaude Code固有の制限
---

# Git操作

dot_gitconfigで定義された豊富なGitエイリアスを含む:

- `g s` / `gs` - Git status
- `g c` / `g cmm` - メッセージ付きGit commit
- `g poh` - origin HEADにpush
- `g graph` - コミットグラフを表示
- `g fsw` - fzfを使用したファジーブランチ切り替え

## Claude Code での Git操作（重要）

`git add` と `git commit` は `&&` で繋げず、別々のBash呼び出しで実行すること。
許可ツール設定が個別コマンドパターンのため、連結すると毎回許可が必要になる。

```bash
# Good: 分割実行
git add <files>
git commit -m "..."

# Bad: 連結実行（許可が必要になる）
git add <files> && git commit -m "..."
```
