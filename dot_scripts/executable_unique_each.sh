#!/bin/bash

# 一時ファイルの作成
tempA=$(mktemp)
tempB=$(mktemp)

# ユーザーからの入力を一時ファイルに保存
echo -e "\e[0;32m最初のテキストを入力してください (Ctrl-D で終了):\e[0m"
cat > "$tempA"
echo ""
echo -e "\e[0;32m次のテキストを入力してください (Ctrl-D で終了):\e[0m"
cat > "$tempB"
echo ""

# ソートして一時ファイルに保存
sort "$tempA" > "${tempA}_sorted"
sort "$tempB" > "${tempB}_sorted"

# commコマンドを使用して、それぞれのファイルに特有の行を抽出
comm -23 "${tempA}_sorted" "${tempB}_sorted" > unique_to_A.txt
comm -13 "${tempA}_sorted" "${tempB}_sorted" > unique_to_B.txt

# 結果の出力
echo -e "\e[0;32m最初のテキストにのみ存在する行:\e[0m"
cat unique_to_A.txt
echo ""
echo -e "\e[0;32m次のテキストにのみ存在する行:\e[0m"
cat unique_to_B.txt
echo ""

# 一時ファイルの削除
rm "$tempA" "$tempB" "${tempA}_sorted" "${tempB}_sorted" unique_to_A.txt unique_to_B.txt
