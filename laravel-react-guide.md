<!--
LARAVEL + REACT + INERTIA.JS GUIDE
Laravel + React + Inertia.js 開発ガイド

このファイルの内容:
1. なぜこの技術スタックなのか
2. Laravel規約とベストプラクティス
3. React + TypeScript規約
4. Inertia.jsの使い方
5. よくある間違いと正しい実装

配置方法:
.claude/laravel-react-guide.md として配置
CLAUDE.md から @.claude/laravel-react-guide.md で参照

対象プロジェクト:
Laravel 12.x + React 18.x + Inertia.js + TypeScript を使用するプロジェクト

最終更新: 2025年12月5日
-->

# Laravel + React + Inertia.js 開発ガイド

## 🎯 なぜこの技術スタックなのか？

### Laravel + React + Inertia.js の利点

#### ✅ API作成の手間がほぼゼロ
```php
// ❌ 従来のSPA（Next.js等）では必要
// /api/articles GET
// /api/articles/:id GET
// /api/articles POST
// /api/articles/:id PUT
// /api/articles/:id DELETE
// 10-50個以上のAPIエンドポイントが必要

// ✅ Inertia.jsでは不要
public function index()
{
    return Inertia::render('Articles/Index', [
        'articles' => Article::with('author')->latest()->paginate(20),
    ]);
}
// これだけ！Inertiaが自動でデータを渡す
```

#### ✅ 開発スピードが速い
- Laravelのバックエンド機能（認証、バリデーション、ORM）
- Reactの豊富なUIライブラリとエコシステム
- Inertiaが両者を自然に接続

#### ✅ メンテナンスしやすい
- TypeScriptによる型安全性
- 明確な責務分離（Backend: Laravel、Frontend: React）
- SSRなしで開発が簡単

#### ✅ 実績豊富
- 多数のプロジェクトで検証済み
- アクティブなコミュニティ
- 豊富なドキュメント

---

## 📚 Laravel規約

### 基本原則

#### 1. `@php`ディレクティブ禁止
```blade
{{-- ❌ Bladeでロジック --}}
@php
    $total = 0;
    foreach ($items as $item) {
        $total += $item->price;
    }
@endphp

{{-- ✅ Controller/Serviceへ --}}
// Controller
return Inertia::render('Order/Show', [
    'order' => $order,
    'total' => $order->calculateTotal(), // Modelメソッド
]);
```

#### 2. Eloquent ORMを最大限活用
```php
// ❌ 生SQLやQuery Builder
$articles = DB::table('articles')
    ->join('users', 'articles.user_id', '=', 'users.id')
    ->select('articles.*', 'users.name')
    ->get();

// ✅ Eloquent ORM
$articles = Article::with('author')->get();
```

#### 3. N+1問題を避ける（Eager Loading必須）
```php
// ❌ N+1問題発生
$articles = Article::all();
foreach ($articles as $article) {
    echo $article->author->name; // 各ループでクエリ実行
}

// ✅ Eager Loading
$articles = Article::with('author')->get();
foreach ($articles as $article) {
    echo $article->author->name; // クエリは1回のみ
}

// ✅ 複数のリレーション
$articles = Article::with(['author', 'category', 'tags'])->get();

// ✅ ネストしたリレーション
$articles = Article::with('author.profile')->get();
```

#### 4. FormRequestでバリデーション
```php
// ❌ Controllerで直接バリデーション
public function store(Request $request)
{
    $validated = $request->validate([
        'title' => 'required|max:255',
        'content' => 'required',
    ]);
    // ...
}

// ✅ FormRequest
// app/Http/Requests/StoreArticleRequest.php
class StoreArticleRequest extends FormRequest
{
    public function rules()
    {
        return [
            'title' => 'required|max:255',
            'content' => 'required',
            'category_id' => 'required|exists:categories,id',
        ];
    }
}

// Controller
public function store(StoreArticleRequest $request)
{
    $article = Article::create($request->validated());
    return redirect()->route('articles.show', $article);
}
```

#### 5. Inertia::render()でReactにデータ渡し
```php
// ✅ 標準的な使い方
public function index()
{
    return Inertia::render('Articles/Index', [
        'articles' => Article::with('author')
            ->latest()
            ->paginate(20),
        'categories' => Category::all(),
    ]);
}

// ✅ 認証ユーザー情報を共有
// app/Http/Middleware/HandleInertiaRequests.php
public function share(Request $request)
{
    return array_merge(parent::share($request), [
        'auth' => [
            'user' => $request->user(),
        ],
        'flash' => [
            'success' => fn () => $request->session()->get('success'),
            'error' => fn () => $request->session()->get('error'),
        ],
    ]);
}
```

### Controllerのベストプラクティス

```php
class ArticleController extends Controller
{
    // ✅ 良い例
    public function index()
    {
        return Inertia::render('Articles/Index', [
            'articles' => Article::with(['author', 'category'])
                ->latest()
                ->paginate(20),
            'categories' => Category::all(),
        ]);
    }
    
    public function store(StoreArticleRequest $request)
    {
        $article = Article::create($request->validated());
        
        return redirect()
            ->route('articles.show', $article)
            ->with('success', '記事を作成しました');
    }
    
    public function update(UpdateArticleRequest $request, Article $article)
    {
        $article->update($request->validated());
        
        return redirect()
            ->route('articles.show', $article)
            ->with('success', '記事を更新しました');
    }
    
    public function destroy(Article $article)
    {
        $article->delete();
        
        return redirect()
            ->route('articles.index')
            ->with('success', '記事を削除しました');
    }
}
```

---

## ⚛️ React + TypeScript規約

### 基本原則

#### 1. TypeScript strictモード必須
```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true
  }
}
```

#### 2. `any`型を避ける
```typescript
// ❌ any型
const handleSubmit = (data: any) => {
  console.log(data.title); // エラー検出できない
};

// ✅ 適切な型定義
interface Article {
  id: number;
  title: string;
  content: string;
  author: User;
}

const handleSubmit = (data: Article) => {
  console.log(data.title); // 型安全
};
```

#### 3. Inertia.jsの`router`を使用（fetchは不要）
```typescript
// ❌ fetch を使用
const handleDelete = async (id: number) => {
  const response = await fetch(`/api/articles/${id}`, {
    method: 'DELETE',
  });
  // リダイレクトやリロードを手動で処理
};

// ✅ Inertia.jsのrouter
import { router } from '@inertiajs/react';

const handleDelete = (id: number) => {
  router.delete(`/articles/${id}`, {
    onSuccess: () => {
      // 自動的にページがリロードされる
    },
    onError: (errors) => {
      console.error('削除に失敗しました', errors);
    },
  });
};
```

#### 4. Tailwind CSSでスタイリング
```tsx
// ❌ インラインスタイル
<div style={{ padding: '1rem', backgroundColor: '#f3f4f6' }}>
  <h1 style={{ fontSize: '1.5rem', fontWeight: 'bold' }}>タイトル</h1>
</div>

// ✅ Tailwind CSS
<div className="p-4 bg-gray-100">
  <h1 className="text-2xl font-bold">タイトル</h1>
</div>
```

#### 5. エラーハンドリングを適切に実装
```typescript
// ✅ 良い例
const Dashboard = ({ articles }: Props) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleDelete = (id: number) => {
    if (!confirm('本当に削除しますか？')) return;
    
    setIsLoading(true);
    setError(null);
    
    router.delete(`/articles/${id}`, {
      onSuccess: () => {
        // 成功処理
      },
      onError: (errors) => {
        setError('削除に失敗しました');
      },
      onFinish: () => {
        setIsLoading(false);
      },
    });
  };

  if (error) {
    return <div className="text-red-600">{error}</div>;
  }

  return (
    <div>
      {/* コンテンツ */}
    </div>
  );
};
```

### コンポーネントのベストプラクティス

```typescript
// ✅ 良い例
'use client'

import { useState } from 'react';
import { router } from '@inertiajs/react';

interface Article {
  id: number;
  title: string;
  content: string;
  author: {
    id: number;
    name: string;
  };
  created_at: string;
}

interface DashboardProps {
  articles: Article[];
  categories: Category[];
}

const Dashboard = ({ articles, categories }: DashboardProps) => {
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleDelete = (id: number) => {
    if (!confirm('本当に削除しますか？')) return;
    
    setIsLoading(true);
    router.delete(`/articles/${id}`, {
      onSuccess: () => {
        // 成功処理
      },
      onError: (errors) => {
        setError('削除に失敗しました');
      },
      onFinish: () => {
        setIsLoading(false);
      },
    });
  };

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-8">
          ダッシュボード
        </h1>
        
        {error && (
          <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
            {error}
          </div>
        )}
        
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {articles.map((article) => (
            <ArticleCard
              key={article.id}
              article={article}
              onDelete={handleDelete}
              isLoading={isLoading}
            />
          ))}
        </div>
      </div>
    </div>
  );
};

export default Dashboard;
```

---

## 🔗 Inertia.jsの使い方

### 基本的なデータフロー

```typescript
// 1. LaravelからReactへデータを渡す
// Controller
return Inertia::render('Articles/Index', [
    'articles' => Article::all(),
]);

// 2. Reactコンポーネントで受け取る
interface Props {
  articles: Article[];
}

const Index = ({ articles }: Props) => {
  return (
    <div>
      {articles.map((article) => (
        <div key={article.id}>{article.title}</div>
      ))}
    </div>
  );
};
```

### フォーム送信

```typescript
import { useForm } from '@inertiajs/react';

const CreateArticle = () => {
  const { data, setData, post, processing, errors } = useForm({
    title: '',
    content: '',
    category_id: '',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    post('/articles');
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={data.title}
        onChange={(e) => setData('title', e.target.value)}
      />
      {errors.title && <div className="text-red-600">{errors.title}</div>}
      
      <textarea
        value={data.content}
        onChange={(e) => setData('content', e.target.value)}
      />
      {errors.content && <div className="text-red-600">{errors.content}</div>}
      
      <button type="submit" disabled={processing}>
        {processing ? '送信中...' : '送信'}
      </button>
    </form>
  );
};
```

### リンクとナビゲーション

```typescript
import { Link } from '@inertiajs/react';

// ✅ Inertia Link
<Link href="/articles" className="text-blue-600">
  記事一覧
</Link>

// ✅ プログラマティックナビゲーション
import { router } from '@inertiajs/react';

const handleClick = () => {
  router.visit('/articles');
};

// ✅ フォームメソッド
router.get('/articles');
router.post('/articles', data);
router.put(`/articles/${id}`, data);
router.delete(`/articles/${id}`);
```

### 共有データの使用

```typescript
import { usePage } from '@inertiajs/react';

const Header = () => {
  const { auth, flash } = usePage().props;

  return (
    <header>
      {auth.user && (
        <div>ようこそ、{auth.user.name}さん</div>
      )}
      
      {flash.success && (
        <div className="bg-green-100">{flash.success}</div>
      )}
    </header>
  );
};
```

---

## 🎨 Tailwind CSS ベストプラクティス

### レスポンシブデザイン
```tsx
<div className="
  w-full
  md:w-1/2
  lg:w-1/3
  xl:w-1/4
  p-4
  md:p-6
  lg:p-8
">
  {/* コンテンツ */}
</div>
```

### ダークモード対応
```tsx
<div className="
  bg-white dark:bg-gray-800
  text-gray-900 dark:text-gray-100
">
  {/* コンテンツ */}
</div>
```

### カスタムクラスの作成
```css
/* resources/css/app.css */
@layer components {
  .btn-primary {
    @apply px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 transition;
  }
}
```

---

## 🚀 パフォーマンス最適化

### Lazy Loading
```typescript
import { lazy, Suspense } from 'react';

const HeavyComponent = lazy(() => import('./HeavyComponent'));

const App = () => (
  <Suspense fallback={<div>読み込み中...</div>}>
    <HeavyComponent />
  </Suspense>
);
```

### メモ化
```typescript
import { useMemo, useCallback } from 'react';

const ExpensiveComponent = ({ items }: Props) => {
  // 計算結果をメモ化
  const total = useMemo(() => {
    return items.reduce((sum, item) => sum + item.price, 0);
  }, [items]);
  
  // 関数をメモ化
  const handleClick = useCallback((id: number) => {
    console.log(id);
  }, []);
  
  return <div>{total}</div>;
};
```

---

## 📝 まとめ

### 重要なポイント
1. **API不要** - Inertia.jsが自動でデータを渡す
2. **型安全** - TypeScript strictモード
3. **N+1回避** - Eager Loading必須
4. **Inertia router** - fetchではなくrouterを使用
5. **Tailwind CSS** - インラインスタイル禁止

### 次のステップ
- [Laravel公式ドキュメント](https://laravel.com/docs)
- [Inertia.js公式ドキュメント](https://inertiajs.com)
- [React公式ドキュメント](https://react.dev)

---

**最終更新日**: 2025年12月5日  
**バージョン**: 2.0.0
