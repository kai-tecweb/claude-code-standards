#!/bin/bash

set -e  # エラーが発生したら即座に終了

echo ""
echo "🔄 Claude Code Standards - 更新"
echo "================================"
echo ""

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# .claudeディレクトリの確認
if [ ! -d ".claude" ]; then
    echo -e "${RED}❌ .claude/ ディレクトリが見つかりません${NC}"
    echo "まず install.sh でインストールしてください"
    exit 1
fi

# バックアップ作成
echo "💾 バックアップを作成中..."
BACKUP_DIR=".claude.backup.$(date +%Y%m%d_%H%M%S)"
cp -r .claude "$BACKUP_DIR"
echo -e "${GREEN}✓${NC} バックアップ: ${BACKUP_DIR}"
echo ""

# ベースURL
BASE_URL="https://raw.githubusercontent.com/iwasaki-dev/claude-code-standards/main"

# 更新するファイルのリスト
declare -a files=(
    "standards.md"
    "error-patterns.md"
)

# 存在するファイルを確認して更新対象に追加
if [ -f ".claude/laravel-react-guide.md" ]; then
    files+=("laravel-react-guide.md")
fi

if [ -f ".claude/node-express-guide.md" ]; then
    files+=("node-express-guide.md")
fi

if [ -f ".claude/aws-guide.md" ]; then
    files+=("aws-guide.md")
fi

# ファイルを更新
echo "📥 最新版をダウンロード中..."
echo ""

for file in "${files[@]}"; do
    echo -n "  - $file ... "
    if curl -sSL -o ".claude/$file" "$BASE_URL/.claude/$file"; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}✗${NC}"
        echo -e "${YELLOW}警告: $file の更新に失敗しました${NC}"
    fi
done

echo ""
echo -e "${GREEN}✅ 更新完了！${NC}"
echo ""
echo "📋 更新されたファイル:"
for file in "${files[@]}"; do
    echo "  - .claude/$file"
done
echo ""
echo -e "${YELLOW}⚠️  CLAUDE.md は手動で確認してください${NC}"
echo "新しい機能や設定が追加されている可能性があります"
echo ""
echo "📚 バックアップ:"
echo "問題がある場合は以下で復元できます:"
echo "  rm -rf .claude"
echo "  mv $BACKUP_DIR .claude"
echo ""
echo -e "${GREEN}Happy Coding! 🚀${NC}"
echo ""
