<!--
CLAUDE CODE DEVELOPMENT STANDARDS
開発原則とコーディング規約

このファイルの内容:
1. 調査と実装の分離原則
2. Git運用ルール
3. 禁止ファイル名パターン
4. 基本的なコーディング規約

配置方法:
プロジェクトルートに .claude/ ディレクトリを作成し、このファイルを配置してください。
CLAUDE.md から @.claude/standards.md で参照できます。

更新頻度: 月1回程度
最終更新: 2025年12月5日
-->

# 開発原則

## 🔍 調査と実装の明確な分離

### 基本ルール
```
❌ 悪い例: 
「このエラーを調べて修正して」
→ 勝手に実装されて動かなくなる

✅ 良い例:
「⚠️ 調査のみ。コード変更は絶対にしない。このエラーの原因を調べて報告して」
→ 調査結果を確認してから実装判断
```

### 推奨フロー
1. **調査依頼** → 結果確認
2. **実装判断** → 承認
3. **実装依頼** → 実行
4. **動作確認** → 次へ

---

## 📝 Git運用ルール

### 1機能1コミット、即プッシュ
- ✅ 機能が完成したらすぐコミット
- ✅ コミットしたらすぐプッシュ
- ❌ 大量の未プッシュコミットを作らない
- ❌ 「あとでまとめてコミット」は禁止

### コミットメッセージの書き方
```bash
[種類] 変更内容の簡潔な説明

詳細（必要に応じて）
```

**種類の例:**
- `[追加]` - 新機能の追加
- `[修正]` - バグ修正
- `[削除]` - ファイルや機能の削除
- `[リファクタ]` - コードの整理
- `[更新]` - ドキュメントや依存関係の更新

**例:**
```bash
[追加] ユーザー登録機能を実装

- メールアドレス認証を追加
- パスワードバリデーションを強化
- エラーメッセージを日本語化
```

---

## 🚫 禁止ファイル名パターン

### 絶対に使ってはいけないファイル名
```
❌ xxx_backup.js        → どれが最新か不明
❌ xxx_old.js           → 同上
❌ xxx_v2.js            → バージョン管理の意味がない
❌ xxx_v3.js            → さらに混乱
❌ simple_final_xxx.js  → 意味不明
❌ new_xxx.js           → いつまで経っても"new"
❌ xxx_test.js          → 一時ファイル放置の原因
❌ xxx_copy.js          → コピーが散乱
❌ xxx_2.js             → 番号管理は破綻する
```

### 理由
**Gitでバージョン管理しているため、ファイル名でのバージョン管理は不要かつ混乱の元**

### 正しいやり方
```bash
# 実験したい場合はブランチを切る
git checkout -b feature/experiment

# 不要になったら削除
git branch -d feature/experiment

# 過去のバージョンが必要なら
git log
git checkout <コミットID> -- path/to/file.js
```

---

## 🗂️ バックアップファイル禁止

### 禁止する理由
- ❌ ファイルが多くなり管理が複雑化
- ❌ Gitの履歴があるため不要
- ❌ どれが最新か分からなくなる
- ❌ ディスク容量の無駄

### 正しいバックアップ方法
```bash
# ブランチで管理
git checkout -b backup/before-refactor

# タグで重要なポイントを記録
git tag -a v1.0.0 -m "リリース前の安定版"

# 必要なら特定のコミットに戻る
git revert <コミットID>
```

---

## 💻 コーディング規約

### 基本原則
- 📝 **分かりやすいコメントを書く**
- 🔄 **コードの重複を避け、モジュール化を優先**
- 📖 **補助動詞を用いた説明的な変数名**（`isLoading`、`hasError`など）
- 🎯 **RORO パターン**（Receive an Object, Return an Object）を必要に応じて使用

### 命名規則

#### ファイル名
```
✅ kebab-case
post-service.ts
user-controller.php
article-repository.js
```

#### クラス・コンポーネント
```
✅ PascalCase
PostService
UserProfile
DashboardLayout
ArticleCard
```

#### 関数・メソッド・変数
```
✅ camelCase
getPostLogs
isLoading
userData
fetchArticles
```

#### 定数
```
✅ UPPER_SNAKE_CASE
MAX_POST_LENGTH
API_TIMEOUT
DEFAULT_PAGE_SIZE
```

#### プライベートメンバー
```
✅ 先頭アンダースコア
_privateMethod
_internalData
_helperFunction
```

### コメントの書き方

#### ✅ 良いコメント
```javascript
// ユーザーの最終ログイン時刻を更新
// パフォーマンス: このクエリは最大500msかかる可能性があるため、
// バックグラウンドジョブでの実行を推奨
user.update({ lastLoginAt: now() });

// NOTE: この処理は本番環境でのみ実行される
if (process.env.NODE_ENV === 'production') {
  sendNotification();
}

// TODO: キャッシュ機能を実装して高速化（2025-12-31まで）
fetchAllUsers();

// FIXME: IE11では動作しない。Polyfillを追加する必要あり
const result = Array.from(new Set(items));
```

#### ❌ 悪いコメント
```javascript
// ユーザーを更新
user.update({ lastLoginAt: now() });

// データを取得
const data = fetchData();

// ループ
for (let i = 0; i < items.length; i++) {
  // 処理
  process(items[i]);
}
```

---

## 📏 コードスタイル

### 基本スタイル
- **セミコロン**: 必須
- **インデント**: 2スペース
- **文字列**: シングルクォート（`'`）
- **Trailing comma**: 最後の要素の後にカンマ
- **1行の文字数**: 80文字を目安（厳密ではない）

### 例
```javascript
// ✅ 良い例
const config = {
  apiUrl: 'https://api.example.com',
  timeout: 3000,
  retries: 3, // Trailing comma
};

function fetchUser(id) {
  return fetch(`${config.apiUrl}/users/${id}`);
}

// ❌ 悪い例
const config = {
  apiUrl: "https://api.example.com",
  timeout: 3000,
  retries: 3
}

function fetchUser(id)
{
  return fetch(config.apiUrl+"/users/"+id)
}
```

---

## 🎯 提案を行う際の注意点

Claude Codeに作業を依頼する際は：

### 変更を個別のステップに分解
```
❌ 悪い例:
「認証機能を実装して」

✅ 良い例:
「ステップ1: ログインフォームを作成（調査のみ）」
「ステップ2: バリデーションを実装」
「ステップ3: 認証ロジックを実装」
「ステップ4: テストを作成」
```

### 各段階で小さなテストを提案
```bash
# ステップ1完了後
npm run test:auth

# ステップ2完了後
php artisan test --filter=LoginTest
```

### 既存のコードを深くレビュー
- 既存の実装パターンを確認
- 命名規則を統一
- 既存の機能を壊さないよう注意

### 運用上の懸念を強調
- パフォーマンスへの影響
- セキュリティリスク
- 既存ユーザーへの影響

---

## 🔄 このドキュメントの更新

新しいパターンが見つかったら：

1. このファイルを編集
2. 変更内容をコミット
3. チームに共有

または、Issueを作成して議論してください。

---

**最終更新日**: 2025年12月5日  
**バージョン**: 2.0.0
