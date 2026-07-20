# シフト管理システム（shift_manager）

[![CI](https://github.com/minaminakamura54b/shift_maneger/actions/workflows/ci.yml/badge.svg)](https://github.com/minaminakamura54b/shift_maneger/actions/workflows/ci.yml)

建設現場向けのシフト管理 Web アプリケーションです。社員を現場に配置（アサイン）し、カレンダーで可視化できます。スマートフォン（縦画面）での利用をメインに設計しています。

## 主な機能

- **現場管理** — 現場名・住所・工期（開始日〜終了日）を登録・編集
- **社員管理** — 氏名・メールアドレス・電話番号を登録・編集
- **配置（アサイン）管理**
  - 社員 × 現場 × 日時で配置を登録
  - ドラッグ＆ドロップに対応したカレンダービュー（PC・スマホ両対応）
  - 現場名・社員名が長い場合でも表の枠内に収まるレイアウト
- **勤怠管理**
  - 出勤・退勤のワンタップ打刻（二重打刻はDB制約＋トランザクションで防止）
  - 日をまたぐ勤務にも対応した打刻ロジック
  - 管理者は全社員の勤怠を社員ごとにまとめて閲覧・修正が可能
- **ユーザー認証**（Devise）
  - メールアドレス確認・パスワード再設定（Resend 経由でメール送信）
  - アカウント削除時、個人の勤怠・配置データは削除される一方、現場データは保持される設計
- **日本語対応** — バリデーションエラーなどのメッセージを日本語化

## 使用技術

| カテゴリ | 技術 |
|---|---|
| 言語 / フレームワーク | Ruby 3.2.9 / Ruby on Rails 8.1.3 |
| データベース | PostgreSQL |
| 認証 | Devise（confirmable / recoverable） |
| メール送信 | Resend |
| フロントエンド | Tailwind CSS, Hotwire（Turbo + Stimulus）, Propshaft |
| テスト | Minitest, Capybara + Selenium |
| Lint / 静的解析 | RuboCop（rubocop-rails-omakase）, Brakeman, bundler-audit |
| CI | GitHub Actions |
| インフラ | AWS Elastic Beanstalk（Docker） |

## セットアップ

### 必要要件

- Ruby 3.2.9（`.ruby-version` 参照）
- PostgreSQL
- Node.js は不要（Tailwind CSS は `tailwindcss-rails` gem 経由でビルド）

### 手順

```bash
# リポジトリを取得
git clone https://github.com/minaminakamura54b/shift_maneger.git
cd shift_maneger

# 依存関係のインストール・DB作成・マイグレーションまで一括実行
bin/setup

# サーバー起動（Tailwind ウォッチャー込み）
bin/dev
```

`http://localhost:3000` にアクセスすると起動します。

初期状態ではユーザーが存在しないため、`db/seeds.rb` を使ってダミーデータ（現場・社員・配置・管理者/一般ユーザー各1名）を投入できます。

```bash
bin/rails db:seed
```

投入後は以下のダミーアカウント（本番には存在しない、ローカル検証専用の値）でログインできます。

| 権限 | メールアドレス | パスワード |
|---|---|---|
| 管理者 | admin@example.com | password |
| 一般ユーザー | tanaka.daisuke@example.com | password |

> ローカル開発・テストでは `config/master.key` が無くても起動できます（Rails が secret_key_base を自動生成します）。本番相当の設定を試す場合は `.env.example` を参考に `.env` を用意してください。

### 環境変数

本番運用や `RAILS_ENV=production` での動作確認に必要な環境変数は [.env.example](.env.example) にまとめています。実際の値は `.env` としてコピーし、リポジトリには含めないでください（`.gitignore` で除外済みです）。

## テスト・Lint

```bash
# 自動テスト
bin/rails test

# Lint
bin/rubocop

# 静的セキュリティ解析
bin/brakeman

# 依存gemの脆弱性チェック
bin/bundler-audit
```

## デプロイ

AWS Elastic Beanstalk（Docker on Amazon Linux 2023）にデプロイしています。`main` ブランチへのマージが本番環境に反映される構成です。Thruster（Rails 8 組み込みHTTPサーバー）がリクエストを受け、内部で Puma にプロキシします。

## ディレクトリ構成（主要部分）

```
app/
  controllers/    # 現場・社員・配置（カレンダー含む）・勤怠 などのコントローラー
  models/         # User / Employee / Site / Assignment / AttendanceRecord
  views/          # ERBテンプレート（Tailwind CSSでスタイリング）
config/
  routes.rb
  locales/ja.yml  # 日本語エラーメッセージ
db/
  schema.rb
  seeds.rb        # ダミーデータ投入用
```

## ライセンス

[MIT License](LICENSE)
