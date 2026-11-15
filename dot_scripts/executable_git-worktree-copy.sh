#!/usr/bin/env bash
# git worktree add で作られた新しいワークツリーへ、メインワークツリーから
# ローカル専用ファイル（mise.local.toml 等）をコピーする post-checkout フック。
#
# ~/.gitconfig の hook.worktree-copy から呼ばれる（.git/hooks や core.hooksPath を
# 使わないので、prek 等がリポジトリに入れるフックと共存する）。
#
# 定義ファイルはメインワークツリー直下の .worktreeinclude（gitignore 形式）。
# Claude Code が読むものと同じファイルなので、git と Claude のどちらで作っても
# 同じものがコピーされる。コミットしたくないリポジトリでは、.worktreeinclude 自体を
# .git/info/exclude に書いて未追跡のまま置けばよい（未追跡でも両者とも読む）。
# 定義に一致し、かつ git の除外対象になっているファイルだけを、既存ファイルを
# 上書きせずにコピーする。Claude Code のワークツリー作成ではこのフックは呼ばれず
# Claude 自身がコピーするため（実測）、二重にコピーされることはない。
#
# フックの終了コードは git worktree add / checkout の終了コードになるため、
# 失敗しても警告を出すだけで常に 0 で終わる（-E で関数内のエラーも ERR トラップに届ける）。
set -Eeuo pipefail

copy_local_files() {
  local prev_head="$1" checkout_flag="$3"

  # ブランチの checkout で、直前の HEAD が null-ref（新規作成）のときだけ動く
  [[ "${checkout_flag}" == 1 ]] || return 0
  [[ "${prev_head}" =~ ^0+$ ]] || return 0

  # clone も null-ref で呼ばれるため、追加ワークツリーかどうかで区別する
  local git_dir common_dir
  git_dir=$(git rev-parse --absolute-git-dir)
  common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
  [[ "${git_dir}" != "${common_dir}" ]] || return 0

  local dst
  dst=$(git rev-parse --show-toplevel)

  # フック実行中は GIT_DIR 等が新しいワークツリーを指しているので、
  # メインワークツリーを操作する前に外す
  unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE

  # bare リポジトリにはコピー元となるメインワークツリーが無い
  local is_bare
  is_bare=$(git --git-dir="${common_dir}" rev-parse --is-bare-repository)
  [[ "${is_bare}" == false ]] || return 0

  # 先頭のエントリがメインワークツリー（--separate-git-dir でも正しく取れる）
  local src line
  line=$(git --git-dir="${common_dir}" worktree list --porcelain | head -n 1)
  src="${line#worktree }"
  [[ -d "${src}" && "${src}" != "${dst}" ]] || return 0

  local def="${src}/.worktreeinclude"
  [[ -f "${def}" ]] || return 0

  # 定義に一致する未追跡ファイルのうち、通常の除外規則でも除外されるものだけ
  git -C "${src}" ls-files -z --others --ignored --exclude-from="${def}" |
    git -C "${src}" check-ignore -z --stdin |
    while IFS= read -r -d '' file; do
      mkdir -p "$(dirname "${dst}/${file}")"
      cp -n -p "${src}/${file}" "${dst}/${file}"
    done
}

trap 'echo "git-worktree-copy: ローカル専用ファイルのコピーに失敗しました" >&2; exit 0' ERR
copy_local_files "$@"
exit 0
