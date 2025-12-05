<!--
COMMON ERROR PATTERNS AND SOLUTIONS
よくあるエラーパターンと解決策

このファイルの内容:
1. 環境混在エラー
2. ハードコーディング問題
3. キャッシュ問題
4. 依存関係の層構造問題
5. bcryptエラー
6. 開発サーバー遅延

配置方法:
.claude/error-patterns.md として配置
CLAUDE.md から @.claude/error-patterns.md で参照

使い方:
エラーが発生したら、このファイルで類似パターンを検索してください。
Claude Codeが自動的に参照します。

最終更新: 2025年12月5日
-->

# よくあるエラーパターンと解決策

## 1. 環境混在エラー

### 症状
- 本番環境なのに動かない
- ローカルでは動くが、デプロイすると失敗
- `.env`の設定が反映されない

### 原因
`.env`がローカル設定のまま（`APP_ENV=local`、`DB_CONNECTION=sqlite`など）

### 確認方法
```bash
# 現在の設定を確認
php artisan config:show database

# 環境変数を確認
php artisan tinker
>>> config('app.env')
>>> config('database.default')
```

### 解決方法
```bash
# ⚠️ 重要: 設定を変更したら必ずキャッシュをクリア
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# 本番環境では最適化も実行
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### 正しい .env 設定
```env
# 開発環境
APP_ENV=local
APP_DEBUG=true
APP_URL=http://localhost:8000
DB_CONNECTION=sqlite
FILESYSTEM_DISK=local

# 本番環境
APP_ENV=production
APP_DEBUG=false
APP_URL=https://example.com
DB_CONNECTION=mysql
DB_HOST=xxx.ap-northeast-1.rds.amazonaws.com
FILESYSTEM_DISK=s3
```

---

## 2. ハードコーディング問題

### 症状
- 開発では動くが本番で動かない
- URLやパスが固定されている
- 環境ごとに手動でコード変更が必要

### 原因
`localhost:3001`や`127.0.0.1`などの直書き

### よくある間違い
```javascript
// ❌ 絶対にやってはいけない
const API_URL = 'http://localhost:3001/api';
const DB_HOST = '127.0.0.1';
const STORAGE_PATH = '/Users/username/project/storage';

// ❌ 本番URLの直書きも同様にダメ
const API_URL = 'https://example.com/api';
```

### 正しい実装
```javascript
// ✅ 環境変数を使用
const API_URL = import.meta.env.VITE_API_BASE_URL || '/api';
const DB_HOST = process.env.DB_HOST;
const STORAGE_PATH = process.env.STORAGE_PATH || './storage';

// ✅ 相対パスを使用
const API_URL = '/api'; // 現在のドメインを自動的に使用
```

### Laravel での実装
```php
// ✅ 環境変数を使用
$apiUrl = config('app.url') . '/api';
$dbHost = config('database.connections.mysql.host');
$storagePath = storage_path();

// ✅ ヘルパー関数を使用
$url = route('api.posts.index');
$path = public_path('images/logo.png');
```

### 環境変数ファイルの作成
```env
# .env.development
VITE_API_BASE_URL=http://localhost:3001/api
DB_HOST=127.0.0.1

# .env.production
VITE_API_BASE_URL=/api
DB_HOST=xxx.ap-northeast-1.rds.amazonaws.com
```

---

## 3. キャッシュ問題

### 症状
- 設定変更が反映されない
- コードを修正しても古い動作のまま
- `.env`を変更しても効果がない

### 原因
Laravelの設定キャッシュ、ビューキャッシュ、ルートキャッシュが残っている

### 解決方法（開発環境）
```bash
# 全てのキャッシュをクリア
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# アプリケーションキャッシュもクリア
php artisan optimize:clear
```

### 解決方法（本番環境）
```bash
# デプロイ後は必ずこの順番で実行
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear

# その後、本番用に最適化
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

### Nginxのキャッシュ問題
```bash
# Nginxのキャッシュをクリア
sudo rm -rf /var/cache/nginx/*
sudo systemctl reload nginx
```

### ブラウザキャッシュの問題
```javascript
// ✅ キャッシュバスターを追加
<script src="/js/app.js?v=<?php echo time(); ?>"></script>

// ✅ またはViteが自動的にハッシュを追加
// vite.config.js
export default {
  build: {
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name].[hash].js',
      },
    },
  },
};
```

---

## 4. 依存関係の層構造問題

### 症状
- エラーを1つ直すと次のエラーが出る
- 複数の問題が重なっている
- 解決が連鎖的に必要

### 例
```
エラー1: レートリミッターが動かない
  ↓ 修正
エラー2: 環境変数が読み込めない
  ↓ 修正
エラー3: ログが書き込めない
  ↓ 修正
エラー4: Redisに接続できない
```

### 原因
複数の問題が層構造になっており、1つ修正しないと次の問題が見えない

### 対処法
```bash
# ✅ 1つ修正したら必ずテスト
php artisan config:clear
php artisan serve
# → 動作確認

# ✅ 次の問題を確認
tail -f storage/logs/laravel.log

# ✅ 1つずつ解決
```

### 教訓
**1つ直したら必ずテストして次の問題を確認する**

一度に複数の修正をすると、どの修正が効いたのか分からなくなる。

---

## 5. bcryptエラー（ブラウザ）

### 症状
- ログイン時に「bcrypt is not defined」
- パスワードハッシュ化がブラウザで失敗
- Node.js用のライブラリがブラウザで動かない

### 原因
**bcryptはNode.js専用で、ブラウザでは動作しない**

### 間違った実装
```javascript
// ❌ ブラウザで実行しようとしている
import bcrypt from 'bcrypt';

const handleLogin = async (password) => {
  const hashed = await bcrypt.hash(password, 10); // エラー！
  // ...
};
```

### 正しい実装
```javascript
// ✅ バックエンドで認証処理
// Frontend (React)
const handleLogin = async (email, password) => {
  // パスワードは平文のまま送信（HTTPSで保護）
  const response = await fetch('/api/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });
  // ...
};

// Backend (Laravel)
public function login(Request $request)
{
    $credentials = $request->only('email', 'password');
    
    // バックエンドでハッシュ化と検証
    if (Auth::attempt($credentials)) {
        return response()->json(['success' => true]);
    }
    
    return response()->json(['error' => 'Invalid credentials'], 401);
}
```

### Inertia.jsの場合
```javascript
// ✅ Inertia.jsを使用
import { router } from '@inertiajs/react';

const handleLogin = (e) => {
  e.preventDefault();
  
  router.post('/login', {
    email,
    password, // 平文のまま送信（HTTPSで保護）
  });
};
```

---

## 6. 開発サーバーが遅い

### 症状
- ページ読み込みに10分以上かかる
- `npm run dev`が遅い
- `php artisan serve`が遅い

### 原因1: ログファイル肥大化
```bash
# ログサイズ確認
ls -lh storage/logs/laravel.log

# 例: -rw-r--r-- 1 www-data www-data 2.5G Dec  5 14:30 laravel.log
```

**解決方法:**
```bash
# ログをクリア
truncate -s 0 storage/logs/laravel.log

# または
echo "" > storage/logs/laravel.log

# ログローテーション設定（推奨）
# config/logging.php
'daily' => [
    'driver' => 'daily',
    'path' => storage_path('logs/laravel.log'),
    'level' => 'debug',
    'days' => 7, // 7日間保持
],
```

### 原因2: SQLiteファイル巨大化
```bash
# データベースサイズ確認
ls -lh database/*.sqlite

# 例: -rw-r--r-- 1 user user 5.2G database.sqlite
```

**解決方法:**
```bash
# データベースをリセット
php artisan migrate:fresh

# または、不要なデータを削除
php artisan tinker
>>> DB::table('old_logs')->truncate();
```

### 原因3: node_modules肥大化
```bash
# サイズ確認
du -sh node_modules/

# 例: 2.5G  node_modules/
```

**解決方法:**
```bash
# 再インストール
rm -rf node_modules
npm install

# または
npm ci  # package-lock.jsonから厳密にインストール
```

### 原因4: 大量のファイル監視
```javascript
// vite.config.js で監視対象を制限
export default {
  server: {
    watch: {
      ignored: [
        '**/node_modules/**',
        '**/vendor/**',
        '**/storage/**',
        '**/.git/**',
      ],
    },
  },
};
```

---

## 7. その他のよくあるエラー

### CORS エラー
```
Access to fetch at 'http://api.example.com' from origin 
'http://localhost:3000' has been blocked by CORS policy
```

**解決方法:**
```php
// Laravel: config/cors.php
'paths' => ['api/*', 'sanctum/csrf-cookie'],
'allowed_origins' => ['http://localhost:3000'],
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
```

### 権限エラー
```
Permission denied: storage/logs/laravel.log
```

**解決方法:**
```bash
sudo chown -R www-data:www-data storage/
sudo chmod -R 775 storage/
```

### メモリ不足
```
Fatal error: Allowed memory size exhausted
```

**解決方法:**
```php
// php.ini
memory_limit = 512M

// または一時的に
ini_set('memory_limit', '512M');
```

### タイムアウト
```
Maximum execution time exceeded
```

**解決方法:**
```php
// php.ini
max_execution_time = 300

// または一時的に
set_time_limit(300);
```

---

## 🔍 デバッグのヒント

### Laravel
```bash
# ログを監視
tail -f storage/logs/laravel.log

# クエリログを有効化
DB::enableQueryLog();
// クエリ実行
dd(DB::getQueryLog());

# Tinkerで対話的にデバッグ
php artisan tinker
>>> User::count()
>>> config('database.default')
```

### React
```javascript
// ブラウザのReact DevToolsを使用
// Consoleでエラーを確認
console.log('Debug:', { data, error, isLoading });

// Network タブでAPIリクエストを確認
```

### Inertia.js
```javascript
// Inertiaリクエストを確認
// Network タブで "X-Inertia" ヘッダーを探す

// デバッグ情報を表示
console.log('Inertia page:', usePage());
```

---

## 📝 新しいエラーパターンの追加

このファイルに含まれていないエラーに遭遇したら：

1. エラーメッセージを記録
2. 原因を特定
3. 解決方法を文書化
4. このファイルに追加
5. コミット & プッシュ

---

**最終更新日**: 2025年12月5日  
**バージョン**: 2.0.0
