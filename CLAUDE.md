# shift_manager

## プロジェクト概要

建設現場向けのシフト管理 Web アプリケーション。社員を現場に配置（アサイン）し、カレンダーで可視化する。

## 技術スタック

- **Ruby on Rails** 8.1.3
- **PostgreSQL** （本番・開発ともに）
- **Devise** — ユーザー認証（confirmable / recoverable 有効）
- **Resend** — メール送信（アカウント確認・パスワード再設定）
- **Tailwind CSS** — スタイリング
- **Hotwire** （Turbo + Stimulus）— SPA ライクな UX
- **Propshaft** — アセットパイプライン


## データモデル

| モデル | 説明 |
|---|---|
| `User` | ログインユーザー（Devise 管理） |
| `Employee` | 社員（name / email / phone） |
| `Site` | 現場（name / address / start_date / end_date） |
| `Assignment` | 社員と現場の配置（employee / site / start_date / start_time / end_date / end_time） |

## 主要ルート

```
/                       # ダッシュボード
/sites                  # 現場一覧・CRUD
/employees              # 社員一覧・CRUD
/assignments            # 配置一覧・CRUD
/assignments/calendar   # カレンダービュー
```

## 開発コマンド

```bash
# サーバー起動（Tailwind ウォッチャー込み）
bin/dev

# テスト実行
bin/rails test

# DB マイグレーション
bin/rails db:migrate

# Lint
bin/rubocop
```

## AWS Elastic Beanstalk 環境

| 項目 | 値 |
|---|---|
| アプリケーション名 | `shift_manager` |
| 環境名 | `shift-manager-prod` |
| リージョン | `ap-northeast-1`（東京） |
| プラットフォーム | Docker running on 64bit Amazon Linux 2023 |
| ブランチ | `main` → `shift-manager-prod` に自動対応 |

### デプロイ手順

```bash
# EB CLI でデプロイ
eb deploy

# ログ確認
eb logs

# 環境の状態確認
eb status
```

### 環境変数（本番）

| 変数名 | 用途 |
|---|---|
| `DATABASE_URL` | PostgreSQL 接続 URL（RDS） |
| `SECRET_KEY_BASE` | Rails セッション暗号化キー |
| `RAILS_MASTER_KEY` | credentials.yml.enc の復号キー |
| `PORT` | コンテナのリッスンポート（80） |
| `RESEND_API_KEY` | Resend の API キー（メール送信用） |
| `MAILER_FROM_ADDRESS` | メール送信元アドレス（Resend で認証済みドメインを指定。未設定時は `onboarding@resend.dev`） |
| `APP_HOST` | 確認メール・パスワード再設定メール内のリンクに使うホスト名（例: `shift-manager-prod.xxxx.ap-northeast-1.elasticbeanstalk.com`） |

### Docker / EB 構成メモ

- `Dockerrun.aws.json` — コンテナポートを 3000 で公開
- `.ebextensions/01_docker.config` — EB 環境変数 `PORT=80` を設定
- Thruster（Rails 8 の組み込み HTTP サーバー）が 80 番でリクエストを受け、内部で Puma (3000) にプロキシする

## ディレクトリ構成（主要ファイル）

```
app/
  controllers/
    assignments_controller.rb  # カレンダービューのロジックも含む
    dashboard_controller.rb
    employees_controller.rb
    sites_controller.rb
  models/
    assignment.rb
    employee.rb
    site.rb
    user.rb
  views/
    assignments/
      calendar.html.erb        # カレンダービュー
config/
  routes.rb
  database.yml                 # 本番は DATABASE_URL を使用
.elasticbeanstalk/
  config.yml                   # EB CLI の設定
.ebextensions/
  01_docker.config             # EB 環境変数・設定
Dockerrun.aws.json             # EB 用 Docker ポートマッピング
```
## コーディングルール
- コメントは日本語で書く
- Tailwindのクラスは既存のスタイルに合わせる
- スマートフォン（縦画面）メインでのデザインにする
