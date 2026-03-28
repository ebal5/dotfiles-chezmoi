# パッケージ管理整理 設計ドキュメント

## 概要

Ubuntu/WSL2環境およびWindows環境のソフトウェア管理について、
重複排除とパッケージ棚卸しを行い、管理方針を明確化する。

## 目的

1. **重複排除**: 複数のパッケージマネージャで同じツールを管理している状態を解消
2. **棚卸し**: 使用していないパッケージを削除し、管理対象を軽量化
3. **方針明確化**: 各パッケージマネージャの役割を定義し、今後の追加時の判断基準を確立

## パッケージ管理方針

### 役割分担

| マネージャ | 役�� | 対象 |
| --- | --- | --- |
| **Nix (flake.nix)** | CLIツール・開発コマンド | 日常的に使うコマンドラインツール全般 |
| **APT** | システム基盤・ビルド依存 | lib\*-dev、build-essential等 + ブートストラップ用最小限ツール |
| **mise** | 言語ランタイムのみ | node, python |
| **winget** | Windows側のツール | Nix CLIツールのWindows対応版 + Windows専用アプリ |

### 判定フロー

```text
CLIツールか？ → Nix
ビルド/コンパイル依存ライブラリか？ → APT
言語ランタイムか？ → mise
root権限で使うことがあるか？ → APT（sudo PATH問題の回避）
Windows専用アプリか？ → winget
```

### 注意事項

- `curl`はAPTとNixの両方に残す（Nix自体のインストールに必要なため）
- `nmap`, `vim`はroot権限で使うためAPTに残す
- Windows側のNode.jsバージョン管理はfnm、PythonはuvでOK

## 変更内容

### flake.nix

#### 追加 (+10)

| パッケージ | Nix属性名 | 理由 |
| --- | --- | --- |
| xh | `xh` | httpie代替（Rust製HTTPクライアント） |
| Zig | `zig` | ビルド環境 |
| chezmoi | `chezmoi` | miseから移行 |
| Git | `git` | miseから移行（最新版が必要） |
| Bitwarden CLI | `bitwarden-cli` | miseから移行 |
| htop | `htop` | APTから移行 |
| miller | `miller` | APTから移行 |
| aria2 | `aria2` | APTから移行 |

#### flake.nix 削除 (-2)

| パッケージ | 理由 |
| --- | --- |
| `jnv` | 不使用。jq + fzfで代替可能 |
| `gibo` | 不使用。`gh api /gitignore/templates/{name}`で代替 |

#### flake.nix 維持

starship, delta, lsd, mcfly, sd, hyperfine, uv, bun, zoxide,
fzf, ripgrep, fd, bat, hexyl, curl, jq, oxker, ov, glow, pueue, actionlint

### setup_ubuntu.sh.tmpl — APT

#### APT 削除 (-7)

| パッケージ | 理由 |
| --- | --- |
| `httpie` | xh（Nix）に置き換え |
| `htop` | Nixへ移行 |
| `miller` | Nixへ移行 |
| `aria2` | Nixへ移行 |
| `protobuf-compiler` | 不使用 |
| `socat` | 不使用 |
| `libnotify-bin` | 不使用（WSL環境で機能しない） |

#### APT 維持

autoconf, build-essential, cmake, curl, dirmngr, gawk, gettext, gpg,
nmap, unzip, vim, libbz2-dev, libcurl4-openssl-dev, libdb-dev,
libffi-dev, libgdbm-dev, liblzma-dev, libncursesw5-dev, libreadline-dev,
libsqlite3-dev, libssl-dev, libz-dev, tk-dev, uuid-dev, zlib1g-dev,
wslu(WSL), fonts-\*(GUI Linux)

### setup_ubuntu.sh.tmpl — mise

#### mise 削除 (-3)

| パッケージ | 理由 |
| --- | --- |
| `bitwarden` | Nixへ移行 |
| `chezmoi` | Nixへ移行 |
| `git` | Nixへ移行 |

#### mise 維持

node, python

### setup_windows.ps1.tmpl — winget

#### winget 追加 (+1)

| パッケージ | winget ID | 理由 |
| --- | --- | --- |
| Zig | `zig.zig` | ビルド環境（Nix側と同期） |

#### winget 削除 (-2)

| パッケージ | 理由 |
| --- | --- |
| `Nushell.Nushell` | 不使用（WSLで代替） |
| `Microsoft.PCManager` | 不要（Windows標準機能で十分） |

#### winget 維持

7zip, cURL, Nmap, jq, CMake, VCRedist x2, vim, PowerToys,
Git, VSCode, WinMerge,
ripgrep, delta, fzf, lsd, bat, fd, hexyl, hyperfine, Starship,
zoxide, mcfly, glow, ov,
uv, Bun, fnm,
Bitwarden, win32yank, npiperelay, chezmoi, Authy,
actionlint, aria2, Miller, Obsidian

## 変更後のパッケージ数

| マネージャ | 変更前 | 変更後 | 差分 |
| --- | --- | --- | --- |
| Nix | 23 | 29 | +6 (追加8, 削除2) |
| APT | 32 | 25 | -7 |
| mise | 5 | 2 | -3 |
| winget | 37 | 36 | -1 (追加1, 削除2) |
| **合計** | **97** | **92** | **-5** |

## マイグレーションガイド

既存環境で本変更を適用する際の手順。
`chezmoi apply`は`executable_once_`スクリプトを再実行しないため、
手動での移行作業が必要。

### Ubuntu/WSL2 環境

#### Step 1: APTパッケージの削除

Nixへ移行するパッケージと不使用パッケージをAPTから削除する。

```bash
sudo apt remove -y httpie htop miller aria2 protobuf-compiler socat libnotify-bin
sudo apt autoremove -y
```

#### Step 2: miseで管理していたツールの削除

Nixへ移行する3ツールをmiseから削除する。
`mise unuse -g`で設定ファイルからの削除とインストール済みバージョンの削除を同時に行う。

```bash
# 現在のバージョンを確認
mise ls bitwarden chezmoi git

# グローバル設定から削除（インストール済みバージョンも自動削除される）
mise unuse -g bitwarden@latest
mise unuse -g chezmoi@latest
mise unuse -g git@latest
```

#### Step 3: Nix flakeの更新・適用

chezmoi sourceの更新後、Nixパッケージを再ビルドする。

```bash
# chezmoi sourceを更新（git pull等）
cd ~/.local/share/chezmoi

# Nix flakeを更新・適用
nix profile upgrade --all
# または明示的に再インストール
nix profile install .
```

#### Step 4: 動作確認

移行したツールがNix経由で動作することを確認する。

```bash
# Nixから入ったことを確認（パスが /nix/store/ 配下であること）
which git      # → /nix/store/.../bin/git
which chezmoi  # → /nix/store/.../bin/chezmoi
which xh       # → /nix/store/.../bin/xh
which htop     # → /nix/store/.../bin/htop
which zig      # → /nix/store/.../bin/zig
which mlr      # → /nix/store/.../bin/mlr (miller)
which aria2c   # → /nix/store/.../bin/aria2c

# root権限ツールがAPTのままであることを確認
which nmap     # → /usr/bin/nmap
which vim      # → /usr/bin/vim

# git/chezmoiが正常動作することを確認
git --version
chezmoi doctor
```

### Windows 環境

#### Step 1: 不要パッケージの削除

```powershell
winget uninstall --id Nushell.Nushell
winget uninstall --id Microsoft.PCManager
```

#### Step 2: 新規パッケージのインストール

```powershell
winget install --id zig.zig --accept-source-agreements --accept-package-agreements -e
```

#### Step 3: 動作確認

```powershell
zig version
```

### トラブルシューティング

#### Nix移行後にchezmoi/gitが見つからない

シェルを再起動してNixのPATHを反映する。

```bash
exec $SHELL -l
```

#### miseがまだ古いツールを参照している

`mise unuse -g`で削除されなかった場合、グローバル設定ファイルを直接確認する。

```bash
# グローバル設定の確認
cat ~/.config/mise/config.toml
# または
cat ~/.tool-versions

# 該当行を削除後
mise reshim
```

#### sudo でNixのツールが使えない

Nixで管理するCLIツールはsudoのPATH問題があるため、
root権限が必要なツール（nmap, vim等）はAPTで管理する方針とする。
もしsudo経由でNixのツールを使う必要がある場合：

```bash
sudo env "PATH=$PATH" <command>
```
