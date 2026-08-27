#!/bin/bash
# `once_setup_ubuntu.sh` の本体。Ubuntu 判定は呼び出し元のランチャー
# （`executable_once_setup_ubuntu.sh.tmpl`）が chezmoi テンプレートで行うため、
# ここには入れない。
#
# REQUIRE_GUI: ランチャーが注入する。「非WSL **かつ** GUI が必要」の意味で、
# 単に「GUIが必要」ではない。WSL では常に false になる。
# ランチャーを経由せず直接実行された場合は判断材料が無いので、安全側
# （フォントを入れない）に倒す。ランチャー経由の既定は非WSLなら true。
REQUIRE_GUI="${REQUIRE_GUI:-false}"

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

kernel_release=$(uname -r)
if [[ ${kernel_release,,} == *microsoft* ]]; then
  # WSL環境用のツール
  sudo apt install -y wslu
fi

if [[ $REQUIRE_GUI == true ]]; then
  # フォントなど独立したLinuxで必要とされるもの
  sudo apt install -y \
    fonts-migmix \
    fonts-ipafont-gothic \
    fonts-ipafont-mincho
fi

# Install Nix
if ! command -v nix >/dev/null 2>&1; then
  # 取得に失敗するとインストーラが黙って何もせず進む（このスクリプトは set -e を使わない）。
  # 既知の弱点だが、bootstrap用インストーラの定型なのでここでは構造を変えない
  # shellcheck disable=SC2312
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"
fi

# Enable Nix flakes support
mkdir -p "$HOME/.config/nix"
if ! grep -q "experimental-features = nix-command flakes" "$HOME/.config/nix/nix.conf" 2>/dev/null; then
  echo "experimental-features = nix-command flakes" >>"$HOME/.config/nix/nix.conf"
fi

# Install tools via Nix flake (if flake.nix exists in dotfiles)
if [[ -f "$HOME/.local/share/chezmoi/flake.nix" ]]; then
  nix flake update "$HOME/.local/share/chezmoi" --no-write-lock-file 2>/dev/null || true
  nix profile add "$HOME/.local/share/chezmoi"
fi

if [[ ! -x "$HOME/.local/bin/mise" ]]; then
  gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0x7413A06D
  # 同上。curl が失敗しても gpg 側で検証に失敗するため、実害は install.sh が空になる程度
  # shellcheck disable=SC2312
  curl https://mise.jdx.dev/install.sh.sig | gpg --decrypt >install.sh
  sh ./install.sh
  rm ./install.sh
fi
mise="$HOME/.local/bin/mise"
$mise use -yg node
$mise use -yg python

# Bitwarden SSH Agent
git clone https://github.com/joaojacome/bitwarden-ssh-agent.git ~/.bw-ssh-agent
if ! cd ~/.bw-ssh-agent; then
  echo "Warning: Failed to change directory to ~/.bw-ssh-agent" >&2
else
  git checkout 6237a3604d640533ad4123d23e23ddfd4e3666d2 >/dev/null 2>&1
fi
if ! cd "$HOME"; then
  echo "Warning: Failed to change directory to $HOME" >&2
fi
