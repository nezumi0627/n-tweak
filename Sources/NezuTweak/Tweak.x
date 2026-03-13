// Tweak.x
// NezuTweak — LINE (jp.naver.line) へのフック
// Logos DSL で UIApplicationDelegate を Hook し、
// アプリ起動後に ModMenu ウィンドウを注入する

#import <UIKit/UIKit.h>
#import "ModMenu/NZModMenuWindow.h"

// ─── ユーティリティ ───────────────────────────────────────────────

/// メインスレッドで安全に実行
static inline void NZRunOnMain(dispatch_block_t block) {
    if ([NSThread isMainThread]) { block(); }
    else { dispatch_async(dispatch_get_main_queue(), block); }
}

// ─── AppDelegate フック ───────────────────────────────────────────
// LINE の AppDelegate クラス名 (class-dump で確認; 最新版は "AppDelegate")
%hook AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    BOOL result = %orig; // 元の実装を呼ぶ

    // 少し遅延してウィンドウを表示（LINEのUIが完全に構築されてから）
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[NZModMenuWindow sharedWindow] show];
    });

    return result;
}

%end

// ─── SceneDelegate フック (iOS 13+ / LINE 最新版) ─────────────────
// LINE が UIWindowScene を使っている場合はこちらが先に呼ばれる
%hook SceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
               options:(UISceneConnectionOptions *)connectionOptions {

    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [[NZModMenuWindow sharedWindow] show];
    });
}

%end

// ─── ctor: tweak ロード時のログ ────────────────────────────────────
%ctor {
    NSLog(@"[NezuTweak] ✅ Loaded into %@", [[NSBundle mainBundle] bundleIdentifier]);
}
