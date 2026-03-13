#!/usr/bin/env bash
# install_to_livecontainer.sh
# NezuTweak.dylib を LiveContainer の Tweaks フォルダへ配置するスクリプト
#
# 使い方:
#   ./install_to_livecontainer.sh [デバイスのIP]
#
# 前提:
#   - make でビルド済み (.build/NezuTweak.dylib が存在する)
#   - デバイスと SSH 接続できる状態 (OpenSSH / Filza など)
#   - LiveContainer がデバイスにインストール済み

set -e

DEVICE_IP="${1:-}"
DYLIB_PATH=".build/arm64-apple-ios14.0/NezuTweak.dylib"

# ─── ローカルビルド確認 ───────────────────────────────────────────
if [ ! -f "$DYLIB_PATH" ]; then
  echo "❌ ビルド済み dylib が見つかりません: $DYLIB_PATH"
  echo "   先に 'make' を実行してください"
  exit 1
fi

echo "✅ dylib: $DYLIB_PATH"

# ─── LC_ID_DYLIB を @loader_path に正規化 ────────────────────────
CURRENT_ID=$(otool -D "$DYLIB_PATH" | tail -1)
echo "📦 現在の LC_ID_DYLIB: $CURRENT_ID"

if [[ "$CURRENT_ID" != "@loader_path/NezuTweak.dylib" ]]; then
  echo "🔧 LC_ID_DYLIB を @loader_path/NezuTweak.dylib に変更..."
  install_name_tool -id "@loader_path/NezuTweak.dylib" "$DYLIB_PATH"
fi

# ─── SSH でデバイスへコピー ──────────────────────────────────────
if [ -z "$DEVICE_IP" ]; then
  echo ""
  echo "ℹ️  デバイスIPが指定されていません。"
  echo "   手動でインストールするには:"
  echo ""
  echo "   1. $DYLIB_PATH を iTunees ファイル共有 or Filza で"
  echo "      LiveContainerのDocumentsフォルダにコピー"
  echo ""
  echo "   2. LiveContainer内のパス:"
  echo "      Documents/Tweaks/NezuTweak.dylib          ← グローバル (全アプリ)"
  echo "      Documents/Tweaks/jp.naver.line/NezuTweak.dylib ← LINE専用"
  echo ""
  echo "   3. LiveContainerのTweaksタブで署名してください"
  exit 0
fi

# SSH コピー
LC_TWEAKS_DIR="/private/var/mobile/Containers/Data/Application"

echo "🔍 LiveContainerのDocumentsを検索中..."
LC_DOCS=$(ssh "root@$DEVICE_IP" \
  "find '$LC_TWEAKS_DIR' -name 'LiveContainer' -type d -path '*/Documents/LiveContainer' 2>/dev/null | head -1")

if [ -z "$LC_DOCS" ]; then
  echo "❌ LiveContainerのDocumentsが見つかりません"
  exit 1
fi

# LINE専用フォルダを作成してコピー
TWEAK_DEST="$(dirname "$LC_DOCS")/Tweaks/jp.naver.line"
echo "📂 コピー先: $TWEAK_DEST"
ssh "root@$DEVICE_IP" "mkdir -p '$TWEAK_DEST'"
scp "$DYLIB_PATH" "root@$DEVICE_IP:$TWEAK_DEST/NezuTweak.dylib"

echo ""
echo "✅ インストール完了！"
echo "   LiveContainer を開いて Tweaks タブから署名してください。"
