#!/bin/bash

# 一時ファイルの作成
tempA=$(mktemp)
tempB=$(mktemp)

# ユーザーからの入力を一時ファイルに保存
echo "最初のテキストを入力してください (Ctrl-D で終了):"
cat > "$tempA"
echo "次のテキストを入力してください (Ctrl-D で終了):"
cat > "$tempB"

# ソートして一時ファイルに保存
sort "$tempA" > "${tempA}_sorted"
sort "$tempB" > "${tempB}_sorted"

# commコマンドを使用して、それぞれのファイルに特有の行を抽出
comm -23 "${tempA}_sorted" "${tempB}_sorted" > unique_to_A.txt
comm -13 "${tempA}_sorted" "${tempB}_sorted" > unique_to_B.txt

# 結果の出力
echo "最初のテキストにのみ存在する行:"
cat unique_to_A.txt
echo "次のテキストにのみ存在する行:"
cat unique_to_B.txt

# 一時ファイルの削除
rm "$tempA" "$tempB" "${tempA}_sorted" "${tempB}_sorted" unique_to_A.txt unique_to_B.txt
