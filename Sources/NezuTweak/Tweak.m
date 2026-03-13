// Tweak.m
// NezuTweak — LiveContainer 対応版
//
// LiveContainer の制約:
//   - CydiaSubstrate / ElleKit は存在しない場合がある
//   - @loader_path ベースで動作する
//   - MH_DYLIB として dlopen される
//   - Logos (%hook) は使えない → ObjC runtime で直接フック
//
// フック戦略:
//   - method_setImplementation で AppDelegate / SceneDelegate をフック
//   - %ctor の代わりに __attribute__((constructor)) を使用

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "ModMenu/NZModMenuWindow.h"

// ─── 型定義 ──────────────────────────────────────────────────────
typedef BOOL (*AppDidFinishLaunching_t)(id, SEL, UIApplication *, NSDictionary *);
typedef void (*SceneWillConnect_t)(id, SEL, UIScene *, UISceneSession *, UISceneConnectionOptions *);

// ─── 元 IMP 保持用 ────────────────────────────────────────────────
static AppDidFinishLaunching_t orig_appDidFinishLaunching = NULL;
static SceneWillConnect_t      orig_sceneWillConnect      = NULL;

// ─── ModMenu 起動ヘルパー ─────────────────────────────────────────
static void NZLaunchModMenu(double delaySec) {
    dispatch_after(
        dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySec * NSEC_PER_SEC)),
        dispatch_get_main_queue(),
        ^{
            NSLog(@"[NezuTweak] 🚀 Launching ModMenu");
            [[NZModMenuWindow sharedWindow] show];
        }
    );
}

// ─── AppDelegate フック実装 ───────────────────────────────────────
static BOOL hook_appDidFinishLaunching(
    id self, SEL _cmd,
    UIApplication *application,
    NSDictionary  *launchOptions)
{
    BOOL result = orig_appDidFinishLaunching
        ? orig_appDidFinishLaunching(self, _cmd, application, launchOptions)
        : YES;

    NZLaunchModMenu(1.2);
    return result;
}

// ─── SceneDelegate フック実装 ─────────────────────────────────────
static void hook_sceneWillConnect(
    id self, SEL _cmd,
    UIScene               *scene,
    UISceneSession        *session,
    UISceneConnectionOptions *options)
{
    if (orig_sceneWillConnect) {
        orig_sceneWillConnect(self, _cmd, scene, session, options);
    }
    NZLaunchModMenu(1.5);
}

// ─── クラスへのフック適用 ─────────────────────────────────────────
static BOOL NZHookAppDelegate(Class cls) {
    if (!cls) return NO;

    SEL sel = @selector(application:didFinishLaunchingWithOptions:);
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return NO;

    orig_appDidFinishLaunching = (AppDidFinishLaunching_t)
        method_setImplementation(m, (IMP)hook_appDidFinishLaunching);

    NSLog(@"[NezuTweak] ✅ Hooked AppDelegate: %@", NSStringFromClass(cls));
    return YES;
}

static BOOL NZHookSceneDelegate(Class cls) {
    if (!cls) return NO;

    SEL sel = @selector(scene:willConnectToSession:options:);
    Method m = class_getInstanceMethod(cls, sel);
    if (!m) return NO;

    orig_sceneWillConnect = (SceneWillConnect_t)
        method_setImplementation(m, (IMP)hook_sceneWillConnect);

    NSLog(@"[NezuTweak] ✅ Hooked SceneDelegate: %@", NSStringFromClass(cls));
    return YES;
}

// ─── AppDelegate クラスを発見する ─────────────────────────────────
// LINE のバージョンによってクラス名が変わるため複数候補を試す
static Class NZFindAppDelegateClass(void) {
    // 優先度順の候補リスト
    NSArray<NSString *> *candidates = @[
        @"AppDelegate",
        @"LINEAppDelegate",
        @"NaverAppDelegate",
        @"LineAppDelegate",
        @"LNAppDelegate",
    ];

    for (NSString *name in candidates) {
        Class cls = NSClassFromString(name);
        if (cls && class_getInstanceMethod(cls,
                @selector(application:didFinishLaunchingWithOptions:))) {
            return cls;
        }
    }

    // フォールバック: UIApplicationDelegate を実装している全クラスをスキャン
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    Class found = nil;
    Protocol *proto = @protocol(UIApplicationDelegate);

    for (unsigned int i = 0; i < count; i++) {
        Class cls = classes[i];
        if (class_conformsToProtocol(cls, proto)) {
            Method m = class_getInstanceMethod(cls,
                @selector(application:didFinishLaunchingWithOptions:));
            if (m) {
                NSString *name = NSStringFromClass(cls);
                // LiveContainer 自身のクラスは除外
                if (![name containsString:@"LiveContainer"] &&
                    ![name containsString:@"LCLC"]) {
                    found = cls;
                    break;
                }
            }
        }
    }
    free(classes);
    return found;
}

static Class NZFindSceneDelegateClass(void) {
    NSArray<NSString *> *candidates = @[
        @"SceneDelegate",
        @"LINESceneDelegate",
        @"NaverSceneDelegate",
        @"LineSceneDelegate",
    ];

    for (NSString *name in candidates) {
        Class cls = NSClassFromString(name);
        if (cls && class_getInstanceMethod(cls,
                @selector(scene:willConnectToSession:options:))) {
            return cls;
        }
    }
    return nil;
}

// ─── ctor ─────────────────────────────────────────────────────────
// __attribute__((constructor)) は dylib が dlopen された瞬間に呼ばれる
// LiveContainer は TweakLoader → dlopen(NezuTweak.dylib) の順で呼ぶ
__attribute__((constructor))
static void NZTweakInit(void) {
    NSLog(@"[NezuTweak] 🔧 Initializing in %@",
          [[NSBundle mainBundle] bundleIdentifier]);

    // アプリのクラスがまだロードされていない場合があるので
    // +load が全部終わった後 (メインランループ開始直前) にフックする
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL hookedApp   = NZHookAppDelegate(NZFindAppDelegateClass());
        BOOL hookedScene = NZHookSceneDelegate(NZFindSceneDelegateClass());

        if (!hookedApp && !hookedScene) {
            NSLog(@"[NezuTweak] ⚠️ No hook target found. Falling back to UIApplicationMain observation.");
            // フォールバック: KVO で UIApplication.delegate をウォッチ
            [[NSNotificationCenter defaultCenter]
                addObserverForName:UIApplicationDidFinishLaunchingNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(NSNotification *note) {
                NZLaunchModMenu(0.5);
            }];
        }
    });
}
