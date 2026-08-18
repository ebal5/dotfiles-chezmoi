#!/usr/bin/env bash
# herdr の Claude Code 連携フックを「入っていれば呼ぶ、無ければ黙って何もしない」
# 形で包むラッパー。
#
# 委譲先の ~/.claude/hooks/herdr-agent-state.sh は herdr 管理
# （`herdr integration install claude` が生成し、更新で上書きされる）なので
# このリポジトリでは複製せず、存在すれば実行するだけにする。
#
# 方針:
#   - フックの失敗でセッションを妨げないよう、最終的な終了コードは常に 0
#   - stdin のフック JSON は委譲先が読むため、素通しする（読み捨て禁止）
#   - socket や pane の判定は委譲先が持っているのでここでは重複させない。
#     HERDR_ENV だけは安価な早期終了のために意図的に二重化している
#     （herdr 側がこの変数をやめたらここの判定も外す）
set -uo pipefail

action="${1:-session}"

# 未インストール／herdr 外の早期終了時は、書き込み側に EPIPE を返さないよう
# stdin を読み捨てておく
drain_stdin_and_exit() {
  cat >/dev/null 2>&1 || true
  exit 0
}

# herdr 配下で動いていないなら何もしない（HERDR_ENV は herdr が注入する）
if [[ "${HERDR_ENV:-}" != "1" ]]; then
  drain_stdin_and_exit
fi

# 委譲先を探す。herdr のインストーラは $HOME 基準で書き込むが、
# CLAUDE_CONFIG_DIR を使う環境も候補に含める。
# インストーラは実行権限を付けるので、実行できないものは未インストール扱いにし、
# shebang を無視して sh で起動するようなことはしない
hook=""
for dir in "$HOME/.claude" "${CLAUDE_CONFIG_DIR:-}"; do
  [[ -n "$dir" ]] || continue
  if [[ -x "$dir/hooks/herdr-agent-state.sh" ]]; then
    hook="$dir/hooks/herdr-agent-state.sh"
    break
  fi
done

# 連携未インストール（`herdr integration install claude` で導入）
if [[ -z "$hook" ]]; then
  drain_stdin_and_exit
fi

"$hook" "$action" || true

exit 0
