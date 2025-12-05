#!/bin/bash

set -e  # エラーが発生したら即座に終了

echo ""
echo "🔐 Claude Code Standards - Complete Edition"
echo "==========================================="
echo ""

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# パスワード認証
echo -e "${BLUE}このインストーラーはComplete Edition用です${NC}"
echo ""
read -sp "パスワードを入力してください: " password
echo ""

# 正しいパスワード（実際のパスワードはシークレットに保管）
CORRECT_PASSWORD="iwasaki2025pro"

if [ "$password" != "$CORRECT_PASSWORD" ]; then
    echo -e "${RED}❌ パスワードが間違っています${NC}"
    echo ""
    echo "パスワードをお持ちでない場合は、配布元にお問い合わせください"
    exit 1
fi

echo -e "${GREEN}✓ 認証成功！${NC}"
echo ""

# 現在のディレクトリ確認
CURRENT_DIR=$(pwd)
echo "📁 インストール先: ${CURRENT_DIR}"
echo ""

# ディレクトリ作成
mkdir -p .claude-pro

# Gist URL（実際のURLに置き換える）
GIST_URL="https://gist.githubusercontent.com/iwasaki-dev/XXXXX/raw"

echo "📥 Complete Edition をダウンロード中..."
echo ""

# ファイルをダウンロード
echo "  - claude-standards-pro.md"
if ! curl -sSL "$GIST_URL/claude-standards-pro.md" -o .claude-pro/claude-standards-pro.md 2>/dev/null; then
    echo -e "${RED}❌ ダウンロードに失敗しました${NC}"
    echo "URL が正しいか確認してください"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ インストール完了！${NC}"
echo ""
echo "📋 次のステップ:"
echo "1. CLAUDE.md に以下を追加:"
echo "   @.claude-pro/claude-standards-pro.md"
echo ""
echo "2. claude コマンドでClaude Codeを起動"
echo ""
echo "📚 Complete Edition に含まれる内容:"
echo "  ✨ 実践的なケーススタディ"
echo "  ✨ 高度な技術的テクニック"
echo "  ✨ AWS コスト最適化"
echo "  ✨ 実際のプロジェクト事例"
echo "  ✨ パフォーマンスチューニング"
echo ""
echo "💡 ヒント:"
echo "  - このファイルは .claude-pro/ に保存されます"
echo "  - パブリック版と併用可能です"
echo "  - 定期的に更新されるので、再実行して最新版を取得してください"
echo ""
echo -e "${GREEN}Happy Coding! 🚀${NC}"
echo ""
