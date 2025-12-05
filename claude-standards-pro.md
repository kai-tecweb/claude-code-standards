# Claude Code Development Standards - Complete Edition

**🔒 このドキュメントは限定公開版です**

40年以上の開発経験と5,000以上のプロジェクトから得られた、より詳細な知見とケーススタディを含む完全版です。

---

## 📚 目次

1. [開発原則の深掘り](#開発原則の深掘り)
2. [実践的なエラー解消ケーススタディ](#実践的なエラー解消ケーススタディ)
3. [Laravel + React + Inertia.js 高度なテクニック](#laravel--react--inertiajs-高度なテクニック)
4. [AWS 最適化とコスト削減](#aws-最適化とコスト削減)
5. [実際のプロジェクト事例](#実際のプロジェクト事例)
6. [パフォーマンスチューニング](#パフォーマンスチューニング)

---

## 開発原則の深掘り

### 調査と実装の分離 - 実践例

#### ケーススタディ1: 環境混在エラーの調査

**状況:**
- 本番環境でアプリが動かない
- ローカルでは正常に動作

**間違ったアプローチ:**
```
開発者: 「本番環境が動かないので修正して」
Claude: [.envを変更、キャッシュをクリア、コードを修正]
→ 何を変更したか分からず、さらに問題が複雑化
```

**正しいアプローチ:**
```
開発者: 「⚠️ 調査のみ。コード変更は絶対にしない。
         本番環境が動かない原因を以下の順で調査：
         1. .envファイルの設定確認
         2. Laravelのログ確認
         3. Nginxのエラーログ確認
         4. 結果を報告」

Claude: [調査結果を報告]
「原因は.envファイルで APP_ENV=local になっているためです。
 本番環境では APP_ENV=production に変更し、
 php artisan config:clear を実行する必要があります」

開発者: 「了解。では .env を修正して config:clear を実行して」
Claude: [承認された作業のみ実行]
```

**教訓:**
- 1つずつ段階的に進める
- 各ステップで結果を確認
- 承認されていない作業はしない

---

### Git運用の実践的パターン

#### ケーススタディ2: 44コミット未プッシュ問題

**問題の経緯:**
```
開発者: 「ローカルで44コミットを作ったけど、
         どれをプッシュすべきか分からない」
```

**原因:**
- 小さな修正ごとにコミット
- プッシュを後回しにした
- コミットメッセージが曖昧

**解決策:**
```bash
# 1. コミット履歴を確認
git log --oneline -44

# 2. 意味のある単位でスカッシュ
git rebase -i HEAD~44

# 3. 今後のルール
[追加] ユーザー登録機能を実装
[修正] バリデーションエラーを修正
↓ コミット後すぐプッシュ
```

**ベストプラクティス:**
```
1機能 = 1ブランチ = 数コミット = すぐプッシュ

例:
feature/user-registration
├── [追加] ユーザー登録フォーム作成 → push
├── [追加] バリデーション実装 → push
└── [追加] テスト作成 → push → PR作成
```

---

## 実践的なエラー解消ケーススタディ

### ケーススタディ3: 依存関係の層構造問題

**実際に発生した問題:**
```
エラー1: レートリミッターが動かない
↓ RateLimiter::for() が見つからない
↓ 調査

エラー2: 環境変数 RATE_LIMIT_MAX が読み込めない
↓ config/app.php に追加
↓ php artisan config:clear

エラー3: ログが書き込めない
↓ storage/logs/ の権限エラー
↓ chmod 775 storage/

エラー4: Redisに接続できない
↓ REDIS_HOST が間違っている
↓ .env修正

最終的に動作
```

**解決のポイント:**
```bash
# ❌ 一度に全部修正しようとする
vim config/app.php
chmod 775 storage/
vim .env
php artisan config:clear
# → どの修正が効いたか分からない

# ✅ 1つずつ修正してテスト
vim config/app.php
php artisan config:clear
php artisan serve  # テスト ← エラー3発見

chmod 775 storage/
php artisan serve  # テスト ← エラー4発見

vim .env
php artisan config:clear
php artisan serve  # テスト ← 成功！
```

---

### ケーススタディ4: 開発サーバー遅延（10分問題）

**状況:**
- ページ読み込みに10分以上
- CPU使用率は低い
- メモリも十分

**原因の特定プロセス:**
```bash
# 1. ログサイズ確認
ls -lh storage/logs/laravel.log
# → 2.5GB！

# 2. SQLiteサイズ確認
ls -lh database/database.sqlite
# → 5.2GB！

# 3. node_modulesサイズ確認
du -sh node_modules/
# → 2.5GB
```

**解決:**
```bash
# ログクリア
truncate -s 0 storage/logs/laravel.log

# データベースリセット
php artisan migrate:fresh --seed

# node_modules再インストール
rm -rf node_modules
npm ci

# 結果: 10秒以下に改善
```

**予防策:**
```php
// config/logging.php
'daily' => [
    'driver' => 'daily',
    'path' => storage_path('logs/laravel.log'),
    'level' => 'debug',
    'days' => 7,  // 7日間のみ保持
],
```

---

## Laravel + React + Inertia.js 高度なテクニック

### 複雑なフォームの実装

#### ケーススタディ5: 動的フィールドを持つフォーム

**要件:**
- ユーザーが任意の数の項目を追加できる
- バリデーションが必要
- Inertia.jsで実装

**実装例:**
```typescript
interface FormData {
  title: string;
  items: Array<{
    name: string;
    quantity: number;
    price: number;
  }>;
}

const CreateOrder = () => {
  const { data, setData, post, processing, errors } = useForm<FormData>({
    title: '',
    items: [{ name: '', quantity: 1, price: 0 }],
  });

  const addItem = () => {
    setData('items', [...data.items, { name: '', quantity: 1, price: 0 }]);
  };

  const removeItem = (index: number) => {
    setData('items', data.items.filter((_, i) => i !== index));
  };

  const updateItem = (index: number, field: keyof typeof data.items[0], value: any) => {
    const newItems = [...data.items];
    newItems[index] = { ...newItems[index], [field]: value };
    setData('items', newItems);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    post('/orders');
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        value={data.title}
        onChange={(e) => setData('title', e.target.value)}
      />
      
      {data.items.map((item, index) => (
        <div key={index}>
          <input
            value={item.name}
            onChange={(e) => updateItem(index, 'name', e.target.value)}
          />
          <input
            type="number"
            value={item.quantity}
            onChange={(e) => updateItem(index, 'quantity', parseInt(e.target.value))}
          />
          <input
            type="number"
            value={item.price}
            onChange={(e) => updateItem(index, 'price', parseFloat(e.target.value))}
          />
          <button type="button" onClick={() => removeItem(index)}>
            削除
          </button>
        </div>
      ))}
      
      <button type="button" onClick={addItem}>項目を追加</button>
      <button type="submit" disabled={processing}>送信</button>
    </form>
  );
};
```

**Laravel側のバリデーション:**
```php
class StoreOrderRequest extends FormRequest
{
    public function rules()
    {
        return [
            'title' => 'required|string|max:255',
            'items' => 'required|array|min:1',
            'items.*.name' => 'required|string|max:255',
            'items.*.quantity' => 'required|integer|min:1',
            'items.*.price' => 'required|numeric|min:0',
        ];
    }
}
```

---

### N+1問題の実践的な回避方法

#### ケーススタディ6: 複雑なリレーションでのN+1

**問題のコード:**
```php
// ❌ N+1問題発生（1 + 100 + 100 + 100 = 301クエリ）
$articles = Article::all();  // 1クエリ

foreach ($articles as $article) {
    $article->author->name;      // 100クエリ
    $article->category->name;    // 100クエリ
    $article->tags->pluck('name'); // 100クエリ
}
```

**解決:**
```php
// ✅ Eager Loading（4クエリのみ）
$articles = Article::with([
    'author',
    'category',
    'tags'
])->get();

foreach ($articles as $article) {
    $article->author->name;      // キャッシュから
    $article->category->name;    // キャッシュから
    $article->tags->pluck('name'); // キャッシュから
}
```

**さらに最適化:**
```php
// ✅ 必要なカラムのみ取得
$articles = Article::with([
    'author:id,name',
    'category:id,name',
    'tags:id,name'
])->select('id', 'title', 'user_id', 'category_id')
  ->get();
```

---

## AWS 最適化とコスト削減

### ケーススタディ7: 月額¥30,000 → ¥8,000への削減

**初期構成（月額¥30,000）:**
```
- EC2 t3.large (マルチAZ) ¥12,000
- RDS MySQL (マルチAZ) ¥15,000
- NAT Gateway ¥3,000
```

**最適化後（月額¥8,000）:**
```
- EC2 t3.medium (シングルAZ) ¥3,500 ← リザーブド
- RDS db.t4g.small (シングルAZ) ¥3,000
- NAT Gateway削除 ¥0 ← Elastic IP直接使用
```

**判断基準:**
```
マルチAZが必要な場合:
✅ ダウンタイムが許されない
✅ SLA保証が必要
✅ 大企業向けサービス

シングルAZで十分な場合:
✅ 中小企業向けサービス
✅ スタートアップ
✅ 短時間のダウンタイムが許容される
```

---

## 実際のプロジェクト事例

### プロジェクト1: AIブログ生成サービス

**概要:**
- Laravel 12 + React 18 + Inertia.js
- 料金プラン: Free ¥0/月 〜 Business ¥10,000/月
- WordPress連携、Mini-LLM統合

**技術的チャレンジ:**
1. WordPress API連携
2. 記事生成のバッチ処理
3. 料金プラン管理

**解決策:**
```php
// WordPress連携
class WordPressService
{
    public function publish(Article $article)
    {
        $response = Http::withBasicAuth(
            config('wordpress.username'),
            config('wordpress.app_password')
        )->post(config('wordpress.url') . '/wp-json/wp/v2/posts', [
            'title' => $article->title,
            'content' => $article->content,
            'status' => 'publish',
        ]);
        
        return $response->json();
    }
}
```

**成果:**
- Phase 1完了、テスト待ち
- ユーザー管理システム構築
- 料金プラン自動リセット実装

---

### プロジェクト2: 名刺管理システム

**概要:**
- 地域別自動採番ID（Y0001形式）
- Google Cloud Vision + GPT-4o でOCR
- 名刺情報の自動抽出

**技術的チャレンジ:**
1. OCR精度の向上
2. 地域別ID管理
3. メールアドレスではなくIDで認証

**解決策:**
```php
// 地域別ID生成
class MemberIdGenerator
{
    public function generate(string $region): string
    {
        $prefix = $this->getRegionPrefix($region);
        $lastId = Member::where('member_id', 'like', $prefix . '%')
            ->orderBy('member_id', 'desc')
            ->value('member_id');
            
        if (!$lastId) {
            return $prefix . '0001';
        }
        
        $number = (int) substr($lastId, 1) + 1;
        return $prefix . str_pad($number, 4, '0', STR_PAD_LEFT);
    }
}
```

**成果:**
- 安定したID管理システム
- OCR統合で手入力不要
- ユーザーがIDを覚えやすい

---

## パフォーマンスチューニング

### データベース最適化

#### インデックス戦略
```sql
-- よく検索されるカラムにインデックス
CREATE INDEX idx_articles_user_id ON articles(user_id);
CREATE INDEX idx_articles_created_at ON articles(created_at);

-- 複合インデックス
CREATE INDEX idx_articles_status_created ON articles(status, created_at);

-- フルテキスト検索
CREATE FULLTEXT INDEX idx_articles_title_content ON articles(title, content);
```

#### クエリ最適化
```php
// ❌ 遅いクエリ
Article::where('created_at', '>', now()->subDays(7))
    ->orderBy('created_at', 'desc')
    ->get();

// ✅ 高速クエリ
Article::whereDate('created_at', '>', now()->subDays(7))
    ->latest('created_at')
    ->select('id', 'title', 'created_at')  // 必要なカラムのみ
    ->get();
```

---

## まとめ

この Complete Edition では以下を提供しました：

1. **実践的なケーススタディ**
   - 実際に発生した問題と解決方法
   - 具体的な数値とコスト

2. **高度なテクニック**
   - 複雑なフォームの実装
   - パフォーマンス最適化
   - AWS コスト削減

3. **実際のプロジェクト事例**
   - AIブログ生成サービス
   - 名刺管理システム

---

**最終更新**: 2025年12月5日  
**バージョン**: 2.0.0 - Complete Edition  
**対象**: 限定公開

このドキュメントは継続的に更新されます。
