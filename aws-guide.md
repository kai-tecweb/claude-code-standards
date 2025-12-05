<!--
AWS CONFIGURATION GUIDE
AWS構成ガイド

このファイルの内容:
1. 標準構成（コスト重視）
2. EC2設定とベストプラクティス
3. RDS設定
4. S3活用方法
5. デプロイフロー
6. なぜLambdaを避けるのか

配置方法:
.claude/aws-guide.md として配置
CLAUDE.md から @.claude/aws-guide.md で参照

対象プロジェクト:
AWSを使用するLaravel、Node.js等のプロジェクト

最終更新: 2025年12月5日
-->

# AWS構成ガイド

## 🏗️ 標準構成（コスト重視）

### シングルAZ構成（月額 ¥8,000〜¥15,000）

```
┌─────────────────────────────────────────┐
│         VPC (ap-northeast-1)            │
│  ┌───────────────────────────────────┐  │
│  │  Public Subnet (ap-northeast-1a)  │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  EC2: t3.medium             │  │  │
│  │  │  - Ubuntu 24.04 LTS        │  │  │
│  │  │  - Nginx + PHP-FPM         │  │  │
│  │  │  - Node.js (PM2)           │  │  │
│  │  │  - Redis                    │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
│  ┌───────────────────────────────────┐  │
│  │  Private Subnet (ap-northeast-1a) │  │
│  │  ┌─────────────────────────────┐  │  │
│  │  │  RDS: MySQL 8.0            │  │  │
│  │  │  - db.t4g.small            │  │  │
│  │  │  - シングルAZ               │  │  │
│  │  └─────────────────────────────┘  │  │
│  └───────────────────────────────────┘  │
└─────────────────────────────────────────┘

External Services:
├── S3: 画像・ファイル保存（プライベート）
└── CloudFront: CDN（必要に応じて）
```

### コスト内訳
```
EC2 t3.medium (1年リザーブド):     ¥3,500/月
RDS db.t4g.small (シングルAZ):     ¥3,000/月
EBS 30GB gp3:                       ¥400/月
RDS ストレージ 20GB:                ¥300/月
Elastic IP:                         無料（使用中）
S3 + 転送量:                       ¥1,000/月
その他（NAT Gateway等）:            ¥0（不使用）
─────────────────────────────────
合計:                              ¥8,200/月
```

---

## 🖥️ EC2標準設定

### AMIとインスタンスタイプ

#### 推奨構成
```
AMI: Ubuntu 24.04 LTS
インスタンスタイプ: t3.medium (2vCPU, 4GB RAM)
ストレージ: 20-30GB gp3
```

#### インスタンスタイプの選択基準
```
t3.small (2GB RAM):     小規模・開発環境
t3.medium (4GB RAM):    中規模・本番環境 ← 推奨
t3.large (8GB RAM):     大規模・高トラフィック
```

### セキュリティグループ

```
Inbound Rules:
┌─────────┬──────┬────────────┬─────────────┐
│ Type    │ Port │ Source     │ Description │
├─────────┼──────┼────────────┼─────────────┤
│ SSH     │ 22   │ YOUR_IP/32 │ 管理用      │
│ HTTP    │ 80   │ 0.0.0.0/0  │ Web         │
│ HTTPS   │ 443  │ 0.0.0.0/0  │ Web (SSL)   │
└─────────┴──────┴────────────┴─────────────┘

Outbound Rules:
└─ All traffic: 0.0.0.0/0 (デフォルト)
```

**重要:** SSH (22) は必ず特定IPのみに制限

### Elastic IP

#### 基本方針
```
✅ 既存の未使用Elastic IPを再利用
❌ 安易に新規作成しない（料金増加の原因）

確認方法:
1. EC2 → Elastic IPs
2. 「Associated instance ID」が空のIPを探す
3. あれば再利用、なければ新規作成
```

### ストレージ設定

```
ボリュームタイプ: gp3 (推奨)
サイズ: 20-30GB
IOPS: 3000 (デフォルト)
スループット: 125 MB/s (デフォルト)

gp3を推奨する理由:
- gp2より20%安い
- パフォーマンスが良い
```

---

## 🗄️ RDS設定

### 標準構成

```
エンジン: MySQL 8.0
インスタンスクラス: db.t4g.small
ストレージ: 20GB gp3
マルチAZ: 無効 (コスト削減)
バックアップ保持期間: 7日
暗号化: 有効
```

### パラメータグループ

```sql
-- 日本語対応
character_set_server=utf8mb4
collation_server=utf8mb4_unicode_ci

-- タイムゾーン
time_zone=Asia/Tokyo

-- 接続数
max_connections=100

-- ログ
slow_query_log=1
long_query_time=2
```

### セキュリティグループ

```
Inbound Rules:
┌──────┬──────┬──────────────┬──────────────┐
│ Type │ Port │ Source       │ Description  │
├──────┼──────┼──────────────┼──────────────┤
│ MySQL│ 3306 │ EC2のSG      │ アプリから   │
└──────┴──────┴──────────────┴──────────────┘

※ 0.0.0.0/0 は絶対に設定しない
```

### バックアップ戦略

```bash
# 自動バックアップ（AWS管理）
保持期間: 7日
バックアップウィンドウ: 深夜2:00-3:00（JST）

# 手動スナップショット（重要なタイミング）
- リリース前
- 大規模データ移行前
- データベーススキーマ変更前
```

---

## 📦 S3活用方法

### バケット設定

```
バケット名: your-project-storage
リージョン: ap-northeast-1
パブリックアクセス: ブロック（デフォルト）
バージョニング: 有効（重要ファイル用）
暗号化: 有効（AES-256）
```

### ディレクトリ構造

```
your-project-storage/
├── uploads/
│   ├── avatars/         # ユーザーアバター
│   ├── articles/        # 記事の画像
│   └── documents/       # PDFなど
├── backups/
│   ├── database/        # DBダンプ
│   └── files/           # ファイルバックアップ
└── temp/                # 一時ファイル（自動削除）
```

### ライフサイクルポリシー

```
temp/ ディレクトリ:
└─ 7日後に自動削除

backups/ ディレクトリ:
├─ 30日後にGlacierへ移行
└─ 90日後に削除
```

### Laravel での設定

```php
// config/filesystems.php
's3' => [
    'driver' => 's3',
    'key' => env('AWS_ACCESS_KEY_ID'),
    'secret' => env('AWS_SECRET_ACCESS_KEY'),
    'region' => env('AWS_DEFAULT_REGION', 'ap-northeast-1'),
    'bucket' => env('AWS_BUCKET'),
    'url' => env('AWS_URL'),
    'endpoint' => env('AWS_ENDPOINT'),
],

// 使用例
Storage::disk('s3')->put('avatars/user-123.jpg', $file);
$url = Storage::disk('s3')->url('avatars/user-123.jpg');
```

### CloudFront との連携（オプション）

```
CloudFrontを使用する場合:
✅ S3への直接アクセスをブロック
✅ OAI（Origin Access Identity）を設定
✅ キャッシュポリシーを最適化
✅ カスタムドメインを設定

コスト:
約 ¥1,000-3,000/月（トラフィック次第）
```

---

## 🚀 デプロイフロー

### 初回セットアップ

```bash
# 1. SSH接続
ssh -i your-key.pem ubuntu@your-ec2-ip

# 2. 必要なソフトウェアをインストール
sudo apt update
sudo apt install -y nginx php8.3-fpm php8.3-mysql php8.3-xml \
  php8.3-curl php8.3-zip nodejs npm redis-server

# 3. Composerインストール
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# 4. プロジェクトクローン
cd /var/www
sudo git clone https://github.com/your-repo/your-project.git
cd your-project

# 5. 依存関係インストール
composer install --no-dev --optimize-autoloader
npm install
npm run build

# 6. 環境設定
sudo cp .env.example .env
sudo nano .env  # 本番環境用に編集
php artisan key:generate

# 7. データベースマイグレーション
php artisan migrate --force

# 8. 権限設定
sudo chown -R www-data:www-data storage/
sudo chmod -R 775 storage/

# 9. Nginxの設定
sudo nano /etc/nginx/sites-available/your-project
sudo ln -s /etc/nginx/sites-available/your-project /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 通常のデプロイ

```bash
#!/bin/bash
# deploy.sh

echo "🚀 デプロイ開始"

# Git pull
git pull origin main

# 依存関係更新
composer install --no-dev --optimize-autoloader
npm install
npm run build

# データベースマイグレーション
php artisan migrate --force

# キャッシュクリア
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# 本番用最適化
php artisan config:cache
php artisan route:cache
php artisan view:cache

# 権限設定
sudo chown -R www-data:www-data storage/
sudo chmod -R 775 storage/

# プロセス再起動（Node.jsアプリの場合）
pm2 restart all

echo "✅ デプロイ完了"
```

### ゼロダウンタイムデプロイ（高度）

```bash
# Blue-Greenデプロイ
/var/www/
├── current -> releases/v1.2.3
├── releases/
│   ├── v1.2.2/
│   └── v1.2.3/
└── shared/
    ├── storage/
    └── .env

# Deployer, Envoyerなどのツールを推奨
```

---

## ⚠️ 使用しないAWSサービス

### ❌ Amazon Lambda

#### Lambdaを避ける理由

**1. Composer依存関係の複雑さ**
```
Laravel + Composer:
├── vendor/ が通常 50-100MB
├── Lambdaのサイズ制限: 50MB (圧縮後)
└── 依存関係が大きすぎて収まらない
```

**2. デバッグが困難**
```
EC2:
├── SSH接続してログ確認
├── リアルタイムでデバッグ
└── 環境を直接確認可能

Lambda:
├── CloudWatch Logsのみ
├── ローカル再現が難しい
└── デバッグに時間がかかる
```

**3. コールドスタート問題**
```
初回リクエスト: 2-5秒の遅延
Laravel起動: さらに1-2秒
合計: 3-7秒の遅延
```

**4. 制御が限られる**
```
EC2:
✅ 自由にソフトウェアをインストール
✅ システム設定を変更可能
✅ 長時間実行可能

Lambda:
❌ 実行環境が制限される
❌ 15分のタイムアウト
❌ カスタマイズが難しい
```

#### いつLambdaを使うか
```
✅ 使って良い場合:
- 単純な関数（画像リサイズなど）
- イベント駆動の処理
- 依存関係が少ない

❌ 避けるべき場合:
- Laravel、Symfonyなど大規模フレームワーク
- 複雑な依存関係
- リアルタイム性が重要
```

### ❌ Amazon SQS

```
代わりに:
✅ Redis + Laravel Queue

理由:
- EC2上のRedisで十分
- 追加コストなし
- シンプルな構成
```

### ❌ Amazon DynamoDB

```
代わりに:
✅ RDS MySQL + Redis

理由:
- SQLに慣れている
- リレーショナルデータに適している
- Laravelとの親和性が高い
```

---

## 🔒 セキュリティベストプラクティス

### 1. IAMユーザー管理

```
✅ Rootユーザーは使わない
✅ IAMユーザーごとに最小権限
✅ MFAを有効化
✅ アクセスキーは定期的にローテーション
```

### 2. セキュリティグループ

```
✅ 必要最小限のポートのみ開放
✅ SSHは特定IPのみ
✅ RDSはEC2からのみアクセス可能
```

### 3. SSL/TLS証明書

```
✅ Let's Encryptで無料証明書
✅ または AWS Certificate Manager (ACM)
✅ HTTP → HTTPS リダイレクト設定
```

### 4. バックアップ

```
✅ RDS自動バックアップ（7日）
✅ EC2のEBSスナップショット（週次）
✅ S3のバージョニング
```

---

## 📊 モニタリング

### CloudWatch

```
監視項目:
├── EC2 CPU使用率（> 80%でアラート）
├── RDS接続数（> 80でアラート）
├── ディスク使用量（> 80%でアラート）
└── アプリケーションエラー（Laravel logs）
```

### ログ管理

```
Laravel logs → CloudWatch Logs
├── storage/logs/laravel.log
└── エラー発生時に通知

Nginx logs:
├── /var/log/nginx/access.log
└── /var/log/nginx/error.log
```

---

## 💰 コスト最適化

### リザーブドインスタンス
```
1年契約: 約40%割引
3年契約: 約60%割引

推奨: 本番環境は1年リザーブド
```

### Savings Plans
```
柔軟性の高い割引プラン
EC2 + Fargate + Lambda に適用可能
```

### スポットインスタンス
```
開発環境・バッチ処理に最適
最大90%割引
```

---

## 📚 まとめ

### 推奨構成
- ✅ **EC2 t3.medium** - コントロールしやすい
- ✅ **RDS MySQL 8.0** - 安定性が高い
- ✅ **S3** - ファイルストレージ
- ❌ **Lambda** - Laravel では避ける

### 月額コスト目安
```
小規模: ¥8,000-10,000
中規模: ¥15,000-25,000
大規模: ¥30,000-50,000+
```

---

**最終更新日**: 2025年12月5日  
**バージョン**: 2.0.0
