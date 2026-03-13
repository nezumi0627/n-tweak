# NezuTweak — LINE Tweak for LiveContainer

LINE (`jp.naver.line`) 向け iOS Tweak。  
**LiveContainer** に直接 `.dylib` を配置して動作します。`.deb` / 脱獄は不要です。

---

## 📦 LiveContainer との互換性

| LC の仕様 | NezuTweak の対応 |
|-----------|----------------|
| `.dylib` を `dlopen` でロード | ✅ `LIBRARY_NAME` ビルド (`.dylib` 出力) |
| `LC_ID_DYLIB = @loader_path/xxx.dylib` が必須 | ✅ Makefile / CI で `install_name_tool` を実行 |
| CydiaSubstrate / ElleKit が存在しない場合がある | ✅ 非依存。純粋な ObjC Runtime (`method_setImplementation`) でフック |
| `%hook` / Logos DSL は使えない | ✅ 使用しない (`Tweak.m` として実装) |
| `TweakLoader` が `dlopen` → `__attribute__((constructor))` が呼ばれる | ✅ `__attribute__((constructor))` でエントリポイント |
| `NSBundle.mainBundle` がゲストに差し替えられている | ✅ バンドルID検証なし |
| `UIWindowScene` がアプリより後に確定することがある | ✅ `dispatch_async(main_queue)` で遅延起動 |
| グローバル / アプリ固有 Tweaks フォルダ | ✅ どちらにも配置可能 |
| 署名が必要 (JIT-less モード) | ✅ LC の自動署名に任せる (dylib 側で不要な設定なし) |

---

## 📁 ディレクトリ構造

```
nezu-tweak/
├── Makefile                          # LIBRARY_NAME ビルド (.dylib 出力)
├── install_to_livecontainer.sh       # デバイスへのコピー補助スクリプト
├── .github/workflows/build.yml       # CI (dylib を成果物として公開)
└── Sources/
    └── NezuTweak/
        ├── Tweak.m                   # ObjC Runtimeフック + __attribute__((constructor))
        └── ModMenu/
            ├── NZModMenuWindow.h/m   # ModMenu ウィンドウ (LC UIWindowScene対応)
            ├── NZMenuButton.h/m      # 浮遊グラデーションボタン
            └── NZAboutViewController.h/m  # About パネル
```

---

## 🚀 ビルド

```bash
export THEOS=/opt/theos
make -j$(nproc)
# → .build/arm64-apple-ios14.0/NezuTweak.dylib
```

CI (GitHub Actions) でも自動ビルドされ、Releases に `NezuTweak.dylib` が添付されます。

---

## 📲 LiveContainer へのインストール

### 方法 A：install スクリプト (SSH 接続ありの場合)

```bash
./install_to_livecontainer.sh <デバイスのIP>
```

### 方法 B：手動 (Filza / iTunesファイル共有)

1. `NezuTweak.dylib` をデバイスに転送
2. LiveContainer の Documents フォルダへコピー:
   ```
   # LINE 専用 (推奨)
   Documents/Tweaks/jp.naver.line/NezuTweak.dylib

   # または グローバル (全アプリに適用)
   Documents/Tweaks/NezuTweak.dylib
   ```
3. LiveContainer → `Tweaks` タブ → `Sign` ボタンで署名
4. LINE を起動 → ⚡ ボタンが画面に表示される

---

## ⚙️ 動作フロー

```
LiveContainer 起動
  └─ LINE (ゲスト) を dlopen
       └─ TweakLoader が NezuTweak.dylib を dlopen
            └─ __attribute__((constructor)) NZTweakInit()
                 ├─ AppDelegate クラスを探索 (複数候補名 + プロトコルスキャン)
                 ├─ method_setImplementation でフック
                 └─ LINE 起動完了後
                      └─ NZModMenuWindow.show()
                           └─ ⚡ 浮遊ボタン表示
                                └─ タップ → ドロワーメニュー
                                     └─ [About] → NZAboutViewController
```

---

## 🎯 機能

| 機能 | 状態 |
|------|------|
| ⚡ Mod Menu 浮遊ボタン (ドラッグ/端スナップ) | ✅ 実装済み |
| ℹ️ About パネル | ✅ 実装済み |
| 🔇 既読スキップ | 🚧 準備中 |
| 👁 オンライン非表示 | 🚧 準備中 |
| 📸 ステルス閲覧 | 🚧 準備中 |
| 💬 送信取消メッセージ復元 | 🚧 準備中 |

---

## ⚠️ 免責事項

本 Tweak は教育・研究目的のみです。  
LINE の利用規約に違反する使用は禁止されています。使用は自己責任でお願いします。

---

## 👤 作者

**nezu**
