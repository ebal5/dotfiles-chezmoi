---
description: docker composeでサービスを起動します
allowed-tools: Bash(docker compose:*)
argument-hint: [サービス名（オプション）]
---

docker composeでサービスを起動してください。

## 実行手順

1. `docker-compose.yml` または `compose.yml` の存在を確認
2. `docker compose up -d $ARGUMENTS` を実行
3. 起動状態を `docker compose ps` で確認
4. 起動したサービスとアクセス方法を報告

## 使用例

- `/docker:compose-up` - 全サービス起動
- `/docker:compose-up web` - 特定サービスのみ
- `/docker:compose-up --build` - ビルド後に起動

## 関連コマンド

- 停止: `docker compose down`
- ログ確認: `docker compose logs -f`
- 再起動: `docker compose restart`
- ステータス: `docker compose ps`

## 注意事項

- `docker-compose` は非推奨です。`docker compose` を使用してください
