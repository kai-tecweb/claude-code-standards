#!/bin/bash

set -e  # エラーが発生したら即座に終了

echo ""
echo "🤖 Claude Code Standards - インストーラー"
echo "=========================================="
echo ""

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 現在のディレクトリ確認
CURRENT_DIR=$(pwd)
echo "📁 インストール先: ${CURRENT_DIR}"
echo ""

# .claudeディレクトリの存在確認
if [ -d ".claude" ]; then
    echo -e "${YELLOW}⚠️  .claude/ ディレクトリが既に存在します${NC}"
    read -p "上書きしますか？ (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "インストールをキャンセルしました"
        exit 1
    fi
    echo "バックアップを作成中..."
    mv .claude .claude.backup.$(date +%Y%m%d_%H%M%S)
fi

# CLAUDE.mdの存在確認
if [ -f "CLAUDE.md" ]; then
    echo -e "${YELLOW}⚠️  CLAUDE.md が既に存在します${NC}"
    read -p "上書きしますか？ (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "CLAUDE.mdはスキップします"
        SKIP_CLAUDE_MD=true
    else
        echo "バックアップを作成中..."
        mv CLAUDE.md CLAUDE.md.backup.$(date +%Y%m%d_%H%M%S)
    fi
fi

# .claudeディレクトリ作成
echo ""
echo "📥 標準ファイルをダウンロード中..."
mkdir -p .claude

# ベースURL
BASE_URL="https://raw.githubusercontent.com/iwasaki-dev/claude-code-standards/main"

# 必須ファイルをダウンロード
echo "  - standards.md"
curl -sSL -o .claude/standards.md "$BASE_URL/.claude/standards.md"

echo "  - error-patterns.md"
curl -sSL -o .claude/error-patterns.md "$BASE_URL/.claude/error-patterns.md"

# 技術スタック選択
echo ""
echo "技術スタックを選択してください："
echo "1) Laravel + React + Inertia"
echo "2) Node.js + Express"
echo "3) 最小構成（標準ファイルのみ）"
read -p "選択 (1-3): " stack_choice

TEMPLATE="CLAUDE.template.md"

case $stack_choice in
  1)
    echo "  - laravel-react-guide.md"
    curl -sSL -o .claude/laravel-react-guide.md "$BASE_URL/.claude/laravel-react-guide.md"
    TEMPLATE="CLAUDE.laravel.md"
    ;;
  2)
    echo "  - node-express-guide.md"
    # curl -sSL -o .claude/node-express-guide.md "$BASE_URL/.claude/node-express-guide.md"
    echo "    ※ Node.js用ガイドは準備中です"
    TEMPLATE="CLAUDE.template.md"
    ;;
  3)
    echo "  - 最小構成を選択しました"
    TEMPLATE="CLAUDE.template.md"
    ;;
  *)
    echo -e "${RED}無効な選択です。デフォルト設定でインストールします${NC}"
    ;;
esac

# AWS使用確認
echo ""
read -p "AWSを使用しますか？ (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  - aws-guide.md"
    curl -sSL -o .claude/aws-guide.md "$BASE_URL/.claude/aws-guide.md"
    USE_AWS=true
fi

# CLAUDE.md作成
if [ "$SKIP_CLAUDE_MD" != true ]; then
    echo ""
    echo "📝 CLAUDE.md を作成中..."
    
    if [ "$TEMPLATE" = "CLAUDE.laravel.md" ]; then
        curl -sSL -o CLAUDE.md "$BASE_URL/templates/$TEMPLATE"
    else
        # 基本テンプレートを作成
        cat > CLAUDE.md << 'EOF'
# [プロジェクト名]

## Commands
# プロジェクト固有のコマンドを記載してください
# 例:
# npm run dev: Start development server
# npm run build: Build for production

## Architecture
# プロジェクトのアーキテクチャを記載してください

## Standards and Best Practices
@.claude/standards.md
@.claude/error-patterns.md

## Project-specific Information
# プロジェクト固有の情報を記載してください
# - 使用している技術
# - 環境変数の説明
# - 開発環境のセットアップ方法
EOF
    fi
    
    # AWS使用の場合、CLAUDE.mdに追記
    if [ "$USE_AWS" = true ]; then
        echo "@.claude/aws-guide.md" >> CLAUDE.md
    fi
fi

echo ""
echo -e "${GREEN}✅ インストール完了！${NC}"
echo ""
echo "📋 次のステップ:"
echo "1. CLAUDE.md を編集してプロジェクト固有情報を追加"
echo "2. claude コマンドでClaude Codeを起動"
echo ""
echo "📚 ファイル構成:"
echo "├── CLAUDE.md                    # プロジェクト設定"
echo "├── .claude/"
echo "│   ├── standards.md             # 開発原則"
echo "│   ├── error-patterns.md        # エラー解消パターン"

if [ "$stack_choice" = "1" ]; then
    echo "│   ├── laravel-react-guide.md   # Laravel+React ガイド"
fi

if [ "$USE_AWS" = true ]; then
    echo "│   └── aws-guide.md             # AWS構成ガイド"
fi

echo ""
echo "💡 ヒント:"
echo "- CLAUDE.mdはGitにコミットしてチームで共有できます"
echo "- .claude/内のファイルは自由にカスタマイズ可能です"
echo "- 最新版への更新: curl -sSL https://... | bash"
echo ""
echo -e "${GREEN}Happy Coding! 🚀${NC}"
echo ""
