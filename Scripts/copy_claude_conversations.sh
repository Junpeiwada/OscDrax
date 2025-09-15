#!/bin/bash

# ClaudeとOscDraxプロジェクトの会話履歴をコピーするスクリプト

# 色付き出力のための定数
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# ソースとターゲットのパス
SOURCE_DIR="/Users/junpeiwada/.claude/projects/-Users-junpeiwada-Documents-Project-OscDrax"
TARGET_DIR="/Users/junpeiwada/Documents/Project/OscDrax/ClaudeCode-Talk"

echo -e "${BLUE}=== Claude会話履歴コピースクリプト ===${NC}"
echo ""

# ソースディレクトリの存在確認
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}エラー: ソースディレクトリが見つかりません${NC}"
    echo "  パス: $SOURCE_DIR"
    exit 1
fi

# ターゲットディレクトリの作成（存在しない場合）
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${YELLOW}ClaudeCode-Talkディレクトリを作成中...${NC}"
    mkdir -p "$TARGET_DIR"
fi

# ファイル数をカウント
FILE_COUNT=$(find "$SOURCE_DIR" -name "*.jsonl" -type f | wc -l | tr -d ' ')

if [ "$FILE_COUNT" -eq 0 ]; then
    echo -e "${YELLOW}警告: コピーするファイルが見つかりません${NC}"
    exit 0
fi

echo -e "${GREEN}$FILE_COUNT 個のファイルをコピー中...${NC}"
echo ""

# ファイルをコピー（進捗表示付き）
COPIED=0
FAILED=0

for file in "$SOURCE_DIR"/*.jsonl; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        echo -n "  コピー中: $filename ... "

        if cp "$file" "$TARGET_DIR/"; then
            echo -e "${GREEN}✓${NC}"
            ((COPIED++))
        else
            echo -e "${RED}✗${NC}"
            ((FAILED++))
        fi
    fi
done

echo ""
echo -e "${BLUE}=== 結果サマリー ===${NC}"
echo -e "  ${GREEN}成功: $COPIED ファイル${NC}"
if [ "$FAILED" -gt 0 ]; then
    echo -e "  ${RED}失敗: $FAILED ファイル${NC}"
fi
echo -e "  保存先: ${BLUE}$TARGET_DIR${NC}"

# ディレクトリサイズを表示
TOTAL_SIZE=$(du -sh "$TARGET_DIR" | cut -f1)
echo -e "  合計サイズ: ${YELLOW}$TOTAL_SIZE${NC}"

echo ""
echo -e "${GREEN}✨ 会話履歴のコピーが完了しました！${NC}"