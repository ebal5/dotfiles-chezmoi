# パッケージ管理整理 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Nix/APT/mise/wingetのパッケージ管理を整理し、重複排除・棚卸し・方針明確化を行う

**Architecture:** 3つの設定ファイル(flake.nix, setup_ubuntu.sh.tmpl, setup_windows.ps1.tmpl)を編集し、CLAUDE.mdにパッケージ管理方針を追記する。各ファイルは独立して編集可能だが、flake.nixを先に変更することでNix側のパッケージ名を確定させる。

**Tech Stack:** Nix flakes, Chezmoi templates (Go template), PowerShell, ShellCheck/shfmt

---

### Task 1: flake.nix — パッケージの追加・削除・整理

**Files:**

- Modify: `flake.nix`

- [ ] **Step 1: パッケージを追加する**

`flake.nix`の`paths`リストに以下を追加する。既存のカテゴリコメントに沿って適切な位置に配置する。

```nix
paths = with pkgs; [
  # Rust-based CLI tools
  starship          # Shell prompt
  delta             # Improved git diff viewer
  lsd               # Modern ls replacement
  mcfly             # Terminal history search
  sd                # sed replacement
  hyperfine         # Benchmarking tool
  xh                # HTTP client (httpie replacement)

  # Python ecosystem
  uv                # Fast Python package installer

  # JavaScript/TypeScript ecosystem
  bun               # Fast JS/TS runtime and package manager

  # Build tools
  zig               # Zig build environment

  # Directory navigation
  zoxide            # Smart cd replacement

  # Additional utilities
  fzf               # Fuzzy finder
  ripgrep           # Fast grep
  fd                # Fast find
  bat               # Syntax-highlighted cat
  hexyl             # Hex viewer
  curl              # Data transfer
  jq                # JSON processor
  aria2             # Download utility
  miller            # Data processing tool
  htop              # Process monitor

  # TUI tools
  oxker             # Docker container TUI manager
  ov                # Feature-rich terminal pager
  glow              # Terminal Markdown renderer

  # Task management
  pueue             # CLI task queue manager

  # Version control & dotfiles
  git               # Version control (latest from nixos-unstable)
  chezmoi           # Dotfiles manager
  bitwarden-cli     # Bitwarden CLI client

  # Linters
  actionlint        # GitHub Actions workflow linter
];
```

注意: `jnv`と`gibo`は削除済み。`xh`, `zig`, `git`, `chezmoi`, `bitwarden-cli`, `htop`, `miller`, `aria2`が新規追加。

- [ ] **Step 2: Nixビルドが通ることを確認する**

```bash
cd /home/ebal5/.local/share/chezmoi/.claude/worktrees/cheeky-wondering-hinton
nix build . --dry-run
```

Expected: エラーなしで完了。パッケージ名が正しければ依存解決が行われる。
もし`bitwarden-cli`でエラーが出た場合、`nix search nixpkgs bitwarden`で正しい属性名を確認する。

- [ ] **Step 3: コミットする**

```bash
git add flake.nix
git commit -m "feat: reorganize Nix packages — add xh/zig/git/chezmoi/bw-cli/htop/miller/aria2, remove jnv/gibo"
```

---

### Task 2: setup_ubuntu.sh.tmpl — APTパッケージとmiseエントリの削除

**Files:**

- Modify: `executable_once_setup_ubuntu.sh.tmpl`

- [ ] **Step 1: APTパッケージリストから7パッケージを削除する**

`sudo apt install -y \`ブロックから以下の行を削除する:

- `aria2 \`
- `htop \`
- `httpie \`
- `libnotify-bin \`
- `miller \`
- `protobuf-compiler \`
- `socat \`

変更後のAPTブロック:

```bash
sudo apt update
sudo apt install -y \
  autoconf \
  build-essential \
  cmake \
  curl \
  dirmngr \
  gawk \
  gettext \
  gpg \
  libbz2-dev \
  libcurl4-openssl-dev \
  libdb-dev \
  libffi-dev \
  libgdbm-dev \
  liblzma-dev \
  libncursesw5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libz-dev \
  nmap \
  tk-dev \
  unzip \
  uuid-dev \
  vim \
  zlib1g-dev
```

- [ ] **Step 2: miseセクションから3ツールの行を削除する**

以下の3行を削除する:

```bash
$mise use -yg bitwarden
$mise use -yg chezmoi
$mise use -yg git
```

変更後のmiseセクション:

```bash
mise="$HOME/.local/bin/mise"
$mise use -yg node
$mise use -yg python
```

- [ ] **Step 3: shfmtとshellcheckを実行する**

```bash
cd /home/ebal5/.local/share/chezmoi/.claude/worktrees/cheeky-wondering-hinton
shfmt -i 2 -ci -w executable_once_setup_ubuntu.sh.tmpl
shellcheck executable_once_setup_ubuntu.sh.tmpl
```

Expected: shfmtはフォーマット修正（あれば適用）。shellcheckはGoテンプレート構文`{{ }}`による警告が出るが、実際のシェルコード部分のエラーがなければOK。

- [ ] **Step 4: コミットする**

```bash
git add executable_once_setup_ubuntu.sh.tmpl
git commit -m "feat: remove APT/mise packages migrated to Nix and unused packages"
```

---

### Task 3: setup_windows.ps1.tmpl — wingetパッケージの追加・削除

**Files:**

- Modify: `executable_once_setup_windows.ps1.tmpl`

- [ ] **Step 1: Nushellを「開発ツール・エディタ」カテゴリから削除する**

変更前:

```powershell
Install-WingetPackages "開発ツール・エディタ" @(
  "Git.Git"
  "Microsoft.VisualStudioCode"
  "Nushell.Nushell"
  "WinMerge.WinMerge"
)
```

変更後:

```powershell
Install-WingetPackages "開発ツール・エディタ" @(
  "Git.Git"
  "Microsoft.VisualStudioCode"
  "WinMerge.WinMerge"
)
```

- [ ] **Step 2: PCManagerを「基本ツール・ユーティリティ」カテゴリから削除する**

変更前:

```powershell
Install-WingetPackages "基本ツール・ユーティリティ" @(
  "7zip.7zip"
  "cURL.cURL"
  "Insecure.Nmap"
  "jqlang.jq"
  "Kitware.CMake"
  "Microsoft.PCManager"
  "Microsoft.VCRedist.2015+.x64"
  "Microsoft.VCRedist.2015+.x86"
  "vim.vim"
  "XP89DCGQ3K6VLD"  # PowerToys
)
```

変更後:

```powershell
Install-WingetPackages "基本ツール・ユーティリティ" @(
  "7zip.7zip"
  "cURL.cURL"
  "Insecure.Nmap"
  "jqlang.jq"
  "Kitware.CMake"
  "Microsoft.VCRedist.2015+.x64"
  "Microsoft.VCRedist.2015+.x86"
  "vim.vim"
  "XP89DCGQ3K6VLD"  # PowerToys
)
```

- [ ] **Step 3: Zigを「開発・Lintツール」カテゴリに追加する**

変更前:

```powershell
Install-WingetPackages "開発・Lintツール" @(
  "rhysd.actionlint"
)
```

変更後:

```powershell
Install-WingetPackages "開発・Lintツール" @(
  "rhysd.actionlint"
  "zig.zig"
)
```

- [ ] **Step 4: コミットする**

```bash
git add executable_once_setup_windows.ps1.tmpl
git commit -m "feat: add zig to winget, remove Nushell and PCManager"
```

---

### Task 4: CLAUDE.md — パッケージ管理方針の追記

**Files:**

- Modify: `CLAUDE.md`

- [ ] **Step 1: 「ツール管理方針」セクションを更新する**

現在の記載:

```markdown
## ツール管理方針

- **Nix**（`flake.nix`）: CLIツール（starship, delta, fzf, ripgrep等）の宣言的管理
- **mise**: 言語ランタイム（Node.js, Python）とバージョン管理
- 使い分け: CLIツールはNix、プロジェクト依存のランタイムはmise
```

更新後:

```markdown
## ツール管理方針

- **Nix**（`flake.nix`）: CLIツール・開発コマンドの宣言的管理（starship, delta, fzf, ripgrep, git, chezmoi等）
- **APT**: システム基盤・ビルド依存（lib*-dev, build-essential等）+ ブートストラップ用最小限ツール + root権限で使うツール（nmap, vim）
- **mise**: 言語ランタイムのみ（Node.js, Python）
- **winget**（Windows）: Nix CLIツールのWindows対応版 + Windows専用アプリ
- 判定基準: CLIツール→Nix、ビルド依存→APT、ランタイム→mise、root権限必要→APT
```

- [ ] **Step 2: markdownlintを実行する**

```bash
cd /home/ebal5/.local/share/chezmoi/.claude/worktrees/cheeky-wondering-hinton
markdownlint-cli2 CLAUDE.md
```

Expected: エラーなし。

- [ ] **Step 3: コミットする**

```bash
git add CLAUDE.md
git commit -m "docs: update tool management policy with package manager roles"
```

---

### Task 5: lint全体チェックと最終確認

**Files:**

- (変更なし — 検証のみ)

- [ ] **Step 1: 変更した全ファイルのlintを実行する**

```bash
cd /home/ebal5/.local/share/chezmoi/.claude/worktrees/cheeky-wondering-hinton
markdownlint-cli2 CLAUDE.md docs/superpowers/specs/2026-03-29-package-management-cleanup-design.md
shfmt -i 2 -ci -d executable_once_setup_ubuntu.sh.tmpl
```

Expected: 全てエラーなし。`shfmt -d`はdiffモードなので差分がなければ出力なし。

- [ ] **Step 2: Nix flakeのドライビルドで最終確認する**

```bash
nix build . --dry-run
```

Expected: エラーなし。

- [ ] **Step 3: git logで変更履歴を確認する**

```bash
git log --oneline -5
```

Expected: Task 1〜4の4コミットが確認できる。
