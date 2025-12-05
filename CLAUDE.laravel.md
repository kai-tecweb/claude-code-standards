# [プロジェクト名]

## Commands

```bash
# 開発サーバー起動
npm run dev                     # Vite開発サーバー
php artisan serve              # Laravelサーバー

# ビルド
npm run build                  # 本番用ビルド

# データベース
php artisan migrate            # マイグレーション実行
php artisan migrate:fresh      # データベースリセット
php artisan db:seed            # シーダー実行

# テスト
php artisan test               # 全テスト実行
php artisan test --filter=UserTest  # 特定テストのみ

# キャッシュ
php artisan config:clear       # 設定キャッシュクリア
php artisan cache:clear        # アプリケーションキャッシュクリア
php artisan optimize:clear     # 全キャッシュクリア

# コード品質
./vendor/bin/phpstan analyse   # 静的解析
./vendor/bin/pint              # コードフォーマット
npm run lint                   # ESLint
```

---

## Architecture

### Tech Stack
- **Backend**: Laravel 12.x (PHP 8.3)
- **Frontend**: React 18.x + TypeScript
- **Bridge**: Inertia.js
- **Styling**: Tailwind CSS 3.x
- **Database**: MySQL 8.0
- **Cache**: Redis
- **Build Tool**: Vite

### Directory Structure
```
├── app/
│   ├── Http/
│   │   ├── Controllers/      # コントローラー
│   │   ├── Requests/          # FormRequest
│   │   └── Middleware/        # ミドルウェア
│   ├── Models/                # Eloquent モデル
│   └── Services/              # ビジネスロジック
├── resources/
│   ├── js/
│   │   ├── Pages/             # Inertia.js ページコンポーネント
│   │   ├── Components/        # 再利用可能なコンポーネント
│   │   └── Layouts/           # レイアウトコンポーネント
│   └── css/
│       └── app.css            # Tailwind CSS
├── routes/
│   └── web.php                # ルート定義
├── database/
│   ├── migrations/            # マイグレーション
│   └── seeders/               # シーダー
└── tests/
    ├── Feature/               # 機能テスト
    └── Unit/                  # ユニットテスト
```

---

## Standards and Best Practices

@.claude/standards.md
@.claude/laravel-react-guide.md
@.claude/error-patterns.md

<!-- AWSを使用する場合はコメントを外す -->
<!-- @.claude/aws-guide.md -->

---

## Project-specific Information

### Database
- **Type**: MySQL 8.0
- **Host**: `DB_HOST` (環境変数)
- **Name**: `DB_DATABASE` (環境変数)

### Authentication
- **System**: Laravel Breeze + Inertia
- **Session**: Database driver
- **Password Reset**: Email

### File Storage
- **Development**: Local (`storage/app/public`)
- **Production**: AWS S3 (環境変数で切り替え)

### Environment Variables
```env
# 開発環境（.env.development）
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
FILESYSTEM_DISK=local
VITE_API_BASE_URL=/

# 本番環境（.env.production）
APP_ENV=production
APP_DEBUG=false
APP_URL=https://your-domain.com
DB_CONNECTION=mysql
DB_HOST=your-rds-endpoint.ap-northeast-1.rds.amazonaws.com
FILESYSTEM_DISK=s3
VITE_API_BASE_URL=/
```

---

## Development Workflow

### 1. 新機能開発
```bash
# ブランチ作成
git checkout -b feature/new-feature

# 開発
# ...

# テスト
php artisan test

# コミット
git add .
git commit -m "[追加] 新機能を実装"
git push origin feature/new-feature
```

### 2. データベース変更
```bash
# マイグレーション作成
php artisan make:migration create_posts_table

# マイグレーション実行
php artisan migrate

# ロールバック（必要に応じて）
php artisan migrate:rollback
```

### 3. コンポーネント作成
```bash
# Controller作成
php artisan make:controller PostController

# Model作成
php artisan make:model Post -m  # マイグレーションも同時作成

# FormRequest作成
php artisan make:request StorePostRequest

# React コンポーネント作成
# resources/js/Pages/Posts/Index.tsx
```

---

## Important Notes

### ⚠️ 本番環境デプロイ時の注意

1. **キャッシュクリア必須**
```bash
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear
```

2. **本番用最適化**
```bash
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

3. **権限設定**
```bash
sudo chown -R www-data:www-data storage/
sudo chmod -R 775 storage/
```

### ⚠️ 環境分離

- ✅ **絶対にハードコーディングしない**
- ✅ **全て環境変数を使用**
- ✅ **`.env`ファイルはGitにコミットしない**

### ⚠️ セキュリティ

- ✅ **`APP_DEBUG=false`（本番）**
- ✅ **CORS設定を適切に**
- ✅ **CSRF保護を有効に**
- ✅ **SQLインジェクション対策（Eloquent使用）**

---

## Troubleshooting

### よくあるエラー

詳細は `@.claude/error-patterns.md` を参照

**クイックフィックス:**
```bash
# 1. キャッシュをクリア
php artisan optimize:clear

# 2. 依存関係を再インストール
composer install
npm install

# 3. 権限を修正
sudo chown -R www-data:www-data storage/
sudo chmod -R 775 storage/

# 4. ログを確認
tail -f storage/logs/laravel.log
```

---

## Team Communication

### Git Commit Messages
```
[追加] 機能の追加
[修正] バグ修正
[削除] 機能の削除
[リファクタ] コードの整理
[更新] ドキュメントや依存関係の更新
```

### Code Review Checklist
- [ ] テストは追加・更新されているか
- [ ] TypeScript の型エラーはないか
- [ ] N+1問題は発生していないか
- [ ] エラーハンドリングは適切か
- [ ] コメントは必要十分か

---

## References

- [Laravel Documentation](https://laravel.com/docs)
- [Inertia.js Documentation](https://inertiajs.com)
- [React Documentation](https://react.dev)
- [Tailwind CSS Documentation](https://tailwindcss.com/docs)

---

**Project Created**: [作成日]  
**Last Updated**: [更新日]  
**Version**: 1.0.0
