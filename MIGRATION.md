# Migration Log

このファイルには過去の重要な変更やマイグレーション手順を記録しています。

## Nix 統合による開発ツール管理への移行

Cargo 経由での個別インストールから Nix による統合管理へ移行する手順。

### 前提条件

- Nix がまだインストールされていない場合は以下でインストール：

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
source ~/.nix-profile/etc/profile.d/nix.sh
```

### 移行手順

#### 1. 既存の Cargo ツールをアンインストール

```bash
# インストール済みのツールを確認
cargo install --list

# 古いセットアップで Cargo 経由でインストールしたツールを削除
cargo uninstall starship
cargo uninstall git-delta
cargo uninstall hyperfine
cargo uninstall jnv
cargo uninstall lsd
cargo uninstall mcfly
cargo uninstall sd
```

#### 2. rye をアンインストール（使用していた場合）

```bash
# rye をアンインストール
rm -rf ~/.rye
# PATH から rye を削除（~/.bashrc や ~/.zshrc の設定を削除）
```

#### 3. Nix flakes を有効化

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

#### 4. dotfiles を更新

```bash
cd ~/.local/share/chezmoi  # または chezmoi cd
git fetch origin claude/add-nix-setup-script-011CV5zfmr9cCtxc5ecFTHxz
git checkout claude/add-nix-setup-script-011CV5zfmr9cCtxc5ecFTHxz
chezmoi apply
```

#### 5. Nix 環境からツールを読み込む

方法A: `nix develop` を使用（開発シェルアプローチ）

```bash
cd ~/.local/share/chezmoi
nix develop  # Nix 環境を読み込んだシェルを開始
```

方法B: `nix profile` を使用（システムワイドなアプローチ）

```bash
nix profile install github:nixos/nixpkgs/nixos-unstable#starship \
  github:nixos/nixpkgs/nixos-unstable#git-delta \
  github:nixos/nixpkgs/nixos-unstable#lsd \
  github:nixos/nixpkgs/nixos-unstable#mcfly \
  github:nixos/nixpkgs/nixos-unstable#sd \
  github:nixos/nixpkgs/nixos-unstable#jnv \
  github:nixos/nixpkgs/nixos-unstable#hyperfine \
  github:nixos/nixpkgs/nixos-unstable#uv \
  github:nixos/nixpkgs/nixos-unstable#zoxide
```

または

```bash
cd ~/.local/share/chezmoi
nix profile install ./flake.nix#devShells.default.buildInputs
```

#### 6. Bash/Zsh 設定の確認と更新

`~/.bashrc` or `~/.zshrc` から以下を確認・削除：

```bash
# 削除対象（Nix で管理されるようになったため不要）
if [ -e "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

# 削除対象（mise から削除）
$mise use -yg zoxide
```

`zoxide` は Nix で管理されるため、既に dotfiles の`.bashrc` に以下が含まれている場合は、そのまま動作します：

```bash
which zoxide >/dev/null && eval "$(zoxide init bash)"
```

#### 7. 環境の確認

```bash
# インストール済みのツールを確認
which starship git-delta lsd mcfly sd jnv hyperfine uv zoxide

# バージョン確認
starship --version
git-delta --version
lsd --version
uv --version
zoxide --version
```

### ロールバック手順

前のセットアップに戻す場合：

```bash
git checkout main  # または前のブランチに戻す
chezmoi apply

# 古い Cargo セットアップを再実行
~/.local/share/chezmoi/executable_once_setup_ubuntu.sh
```

### トラブルシューティング

**ツールが見つからない**

```bash
# Nix 環境が正しく設定されているか確認
nix flake check ~/.local/share/chezmoi

# 手動で Nix 環境を読み込む
source ~/.nix-profile/etc/profile.d/nix.sh
nix develop ~/.local/share/chezmoi
```

**PATH の問題**

Nix でインストールしたツールが PATH に含まれていない場合：

```bash
# ~/.bashrc または ~/.zshrc に以下を追加
export PATH="$HOME/.nix-profile/bin:$PATH"
```

---

## rtx -> mise への名前変更に追従

mise のインストールを含めたマイグレーションスクリプト。
以下 3 つについては mise 標準のマイグレーションではだめなことがわかっているので自前で実施。

- Git の再インストール
- Python の再インストール
- Ruby の再インストール

```shell
set -euo pipefail
IFS=$'\n\t'

if [ ! -x "$HOME/.local/bin/mise" ]; then
  gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0x7413A06D
  tmpfile=$(mktemp)
  curl https://mise.jdx.dev/install.sh.sig | gpg --decrypt > "$tmpfile"
  sh "$tmpfile"
  rm -f "$tmpfile"
fi
if [ -x "$HOME/.local/share/rtx/bin/rtx" ]; then
  "$HOME/.local/share/rtx/bin/rtx" uninstall git --all
  "$HOME/.local/bin/mise" use -yg git
  for v in $(~/.local/share/rtx/bin/rtx ls python | cut -d " " -f 2); do
    "$HOME/.local/bin/mise" install -y python@$v
  done
  for v in $(~/.local/share/rtx/bin/rtx ls ruby | cut -d " " -f 2); do
    "$HOME/.local/bin/mise" install -y ruby@$v
  done
fi
```
