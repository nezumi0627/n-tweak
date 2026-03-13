// Tweak.m
// NezuTweak — LiveContainer 対応版

#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "ModMenu/NZModMenuWindow.h"

// ─── 型定義 ──────────────────────────────────────────────────────
typedef BOOL (*AppDidFinishLaunching_t)(id, SEL, UIApplication *, NSDictionary *);
typedef void (*SceneWillConnect_t)(id, SEL, UIScene *, UISceneSession *, UISceneConnectionOptions *);

// ─── 元 IMP 保持用 ────────────────────────────────────────────────
static AppDidFinishLaunching_t orig_appDidFinishLaunching = NULL;
static SceneWillConnect_t      orig_sceneWillConnect      = NULL;

// ─── 最前面の ViewController を取得 (keyWindow 非使用) ────────────
static UIViewController *NZTopViewController(void) {
    UIWindow *win = nil;

    // iOS 13+: UIWindowScene 経由
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        UIWindowScene *ws = (UIWindowScene *)scene;
        for (UIWindow *w in ws.windows) {
            if (w.isKeyWindow) { win = w; break; }
        }
        if (!win) win = ws.windows.firstObject;
        if (win) break;
    }

    UIViewController *vc = win.rootViewController;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

// ─── inject 通知アラート ──────────────────────────────────────────
static void NZShowInjectAlert(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"unknown";

        UIAlertController *alert = [UIAlertController
            alertControllerWithTitle:@"⚡ NezuTweak"
                             message:[NSString stringWithFormat:
                                      @"Injected into\n%@\n\nv0.1.0 by nezu", bundleID]
                      preferredStyle:UIAlertControllerStyleAlert];

        [alert addAction:[UIAlertAction
            actionWithTitle:@"OK"
                      style:UIAlertActionStyleDefault
                    handler:nil]];

        UIViewController *top = NZTopViewController();
        if (top) {
            [top presentViewController:alert animated:YES completion:nil];
        }
    });
}

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

    NZShowInjectAlert();
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
    NZShowInjectAlert();
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
static Class NZFindAppDelegateClass(void) {
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
                NSString *n = NSStringFromClass(cls);
                if (![n containsString:@"LiveContainer"] &&
                    ![n containsString:@"LCLC"]) {
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
__attribute__((constructor))
static void NZTweakInit(void) {
    NSLog(@"[NezuTweak] 🔧 Initializing in %@",
          [[NSBundle mainBundle] bundleIdentifier]);

    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL hookedApp   = NZHookAppDelegate(NZFindAppDelegateClass());
        BOOL hookedScene = NZHookSceneDelegate(NZFindSceneDelegateClass());

        if (!hookedApp && !hookedScene) {
            NSLog(@"[NezuTweak] ⚠️ No hook target found. Falling back to notification.");
            [[NSNotificationCenter defaultCenter]
                addObserverForName:UIApplicationDidFinishLaunchingNotification
                            object:nil
                             queue:[NSOperationQueue mainQueue]
                        usingBlock:^(NSNotification *note) {
                NZShowInjectAlert();
                NZLaunchModMenu(0.5);
            }];
        }
    });
}
