# RTK (Rust Token Killer) Integration

rtk は Claude Code の Bash コマンドをトークン効率の高い形にリライトする
PreToolUse フック。リライトルールは rtk バイナリの Rust registry が単一の
情報源であり、`rtk rewrite <cmd>` で事前確認できる。

## Exit Code 契約

| Exit | 意味 | フックの挙動 | 許可リストへの影響 |
| --- | --- | --- | --- |
| 0 | リライトあり | `permissionDecision: allow` を返し auto-allow | 不要（ただし防御的追加は可） |
| 1 | リライトなし（pass-through） | 原文のまま通す | 既存パターンがそのまま機能 |
| 2 | deny ルールマッチ | リライトせず素通し | 既存 deny ルールが機能 |
| 3 | ask ルールマッチ | リライトはするが auto-allow しない | **rtk-prefixed の ask エントリが必須** |

## 許可リスト追加ルール

rtk がリライトする（exit 0 または 3）コマンドは、Claude Code の permission
check に rewritten form で渡るため、既存の非プレフィックスパターンでは
マッチしない。

- **exit 3 (ask)**: rtk-prefixed の ask エントリを**必ず**追加。
  これを怠ると fallback プロンプトが毎回出る
- **exit 0 (auto-allow)**: フックが自動許可するため不要だが、フック不動作時の
  バックストップとして allow 側にも追加するのが安全

例: `git push *` を ask にしているなら、`rtk git push *` も ask に追加する。

## 動作確認コマンド

```bash
# 任意コマンドの変換先と exit code を確認
rtk rewrite "git push origin main"
# → [0] rtk git push origin main（auto-allow される）

# ask 扱いかどうか
rtk rewrite "git push"
# → [3] rtk git push（プロンプトが出る）

# passthrough 確認
rtk rewrite "jq ."
# → [1]（何も出力されず exit 1）
```

新しいリライトルールが rtk に追加された際は、上記コマンドで確認の上、
`dot_claude/settings.json.src` の allow/ask に rtk-prefixed エントリを追加する。

## 関連ファイル

- フックスクリプト: `dot_claude/hooks/executable_rtk-rewrite.sh`
- フック登録: `dot_claude/settings.json.src` の `hooks.PreToolUse`
- 自動更新 PR: `.github/workflows/rtk-update.yml`
