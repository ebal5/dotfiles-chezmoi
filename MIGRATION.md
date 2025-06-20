# Migration Log

このファイルには過去の重要な変更やマイグレーション手順を記録しています。

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
