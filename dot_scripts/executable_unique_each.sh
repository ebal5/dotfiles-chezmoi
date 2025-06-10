#!/usr/bin/env bash
set -euo pipefail

# 依存関係チェック
check_dependencies() {
  local deps=("$@")
  for dep in "${deps[@]}"; do
    if ! command -v "$dep" >/dev/null 2>&1; then
      echo "Error: $dep is required but not installed." >&2
      exit 1
    fi
  done
}

# 一時ファイルとクリーンアップ関数の初期化
tempA=""
tempB=""
tempA_sorted=""
tempB_sorted=""
output_files=()

cleanup() {
  local files=("$tempA" "$tempB" "$tempA_sorted" "$tempB_sorted" "${output_files[@]}")
  for file in "${files[@]}"; do
    if [[ -n "$file" && -f "$file" ]]; then
      rm -f "$file" 2>/dev/null
    fi
  done
}
trap cleanup EXIT

# 必要なコマンドのチェック
check_dependencies sort comm mktemp

# セキュアな一時ファイルの作成
tempA=$(mktemp) && chmod 600 "$tempA"
tempB=$(mktemp) && chmod 600 "$tempB"
tempA_sorted="${tempA}_sorted"
tempB_sorted="${tempB}_sorted"

GREEN="\e[0;32m"
RESET="\e[0m"

# ユーザーからの入力を一時ファイルに保存
echo -e "${GREEN}最初のテキストを入力してください (Ctrl-D で終了):${RESET}"
cat >"$tempA"
echo ""
echo -e "${GREEN}次のテキストを入力してください (Ctrl-D で終了):${RESET}"
cat >"$tempB"
echo ""

# ソートして一時ファイルに保存
sort "$tempA" >"$tempA_sorted"
sort "$tempB" >"$tempB_sorted"

# 出力ファイルの作成とクリーンアップ用の追跡
output_files=("unique_to_A.txt" "unique_to_B.txt")

# commコマンドを使用して、それぞれのファイルに特有の行を抽出
comm -23 "$tempA_sorted" "$tempB_sorted" >"${output_files[0]}"
comm -13 "$tempA_sorted" "$tempB_sorted" >"${output_files[1]}"

# 結果の出力
echo -e "${GREEN}最初のテキストにのみ存在する行:${RESET}"
cat "${output_files[0]}"
echo ""
echo -e "${GREEN}次のテキストにのみ存在する行:${RESET}"
cat "${output_files[1]}"
echo ""
