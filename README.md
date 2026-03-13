# NezuTweak — LINE Mod Menu

LINE アプリ (`jp.naver.line`) 向けの iOS Tweak。  
浮遊ドラッグ可能な **Mod Menu** を注入し、**About パネル**などの機能を提供します。

---

## 📁 ディレクトリ構造

```
nezu-tweak/
├── Makefile                          # Theos ビルド設定
├── NezuTweak.plist                   # Bundle Filter (jp.naver.line)
├── Package.swift                     # CI 互換ダミー
├── layout/
│   └── DEBIAN/
│       └── control                   # .deb パッケージメタデータ
└── Sources/
    └── NezuTweak/
        ├── Tweak.x                   # Logos フック (AppDelegate / SceneDelegate)
        └── ModMenu/
            ├── NZModMenuWindow.h/m   # メインModMenuウィンドウ + ドロワー
            ├── NZMenuButton.h/m      # 浮遊グラデーションボタン
            └── NZAboutViewController.h/m  # About パネル
```

---

## 🚀 ビルド方法

### 必要環境
- macOS または Linux with [Theos](https://theos.dev/)
- Xcode Command Line Tools
- arm64 対応 iOS デバイス (iOS 14.0+)

### ビルド & インストール

```bash
# 環境変数 (Theos がインストール済みの場合)
export THEOS=/opt/theos

# ビルド
make -j$(nproc)

# デバイスへ直接インストール (SSH 接続済みの場合)
make package install THEOS_DEVICE_IP=<デバイスのIP>
```

### .deb のみ生成

```bash
make package
# .deb は packages/ ディレクトリに出力されます
```

---

## 🎯 機能

| 機能 | 状態 |
|------|------|
| ⚡ Mod Menu 浮遊ボタン (ドラッグ/スナップ) | ✅ 実装済み |
| ℹ️ About パネル | ✅ 実装済み |
| 🔇 既読スキップ | 🚧 準備中 |
| 👁 オンライン非表示 | 🚧 準備中 |
| 📸 ステルス閲覧 | 🚧 準備中 |
| 💬 送信取消メッセージ復元 | 🚧 準備中 |

---

## 🔧 カスタマイズ

`Tweak.x` の `AppDelegate` / `SceneDelegate` クラス名は LINE のバージョンによって変わる場合があります。  
最新の LINE に対応するには class-dump でクラス名を確認してください:

```bash
class-dump -H /path/to/LINE.app/LINE -o /tmp/LINE-headers/
grep -r "applicationDidFinishLaunching" /tmp/LINE-headers/
```

---

## ⚠️ 免責事項

本 Tweak は教育・研究目的のみです。  
LINE の利用規約に違反する使用は禁止されています。使用は自己責任でお願いします。

---

## 👤 作者

**nezu**
