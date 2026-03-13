// NZModMenuWindow.m
// NezuTweak — LiveContainer 対応 ModMenu 実装
//
// LiveContainer 固有の考慮事項:
//   - NSBundle.mainBundle はゲストアプリに差し替えられている
//   - UIWindowScene の取得タイミングに注意
//   - UIWindow.windowLevel は LCのウィンドウより上にする必要がある
//   - @loader_path 環境で動作 (絶対パスは使わない)

#import "NZModMenuWindow.h"
#import "NZMenuButton.h"
#import "NZAboutViewController.h"

// ─── カラーパレット ────────────────────────────────────────────────
#define NZ_BG_COLOR      [UIColor colorWithRed:0.10 green:0.10 blue:0.14 alpha:0.95]
#define NZ_ACCENT_COLOR  [UIColor colorWithRed:0.00 green:0.80 blue:0.47 alpha:1.00]
#define NZ_CELL_COLOR    [UIColor colorWithRed:0.15 green:0.15 blue:0.20 alpha:1.00]
#define NZ_TEXT_COLOR    [UIColor whiteColor]
#define NZ_SUB_COLOR     [UIColor colorWithWhite:0.60 alpha:1.00]

static const CGFloat kMenuWidth    = 280.0;
static const CGFloat kRowHeight    = 50.0;
static const CGFloat kHeaderHeight = 56.0;
static const CGFloat kCornerRadius = 14.0;
static const CGFloat kButtonSize   = 54.0;

// ──────────────────────────────────────────────────────────────────
#pragma mark - NZMenuItem

@implementation NZMenuItem

+ (instancetype)buttonWithTitle:(NSString *)title action:(void(^)(void))action {
    NZMenuItem *item = [NZMenuItem new];
    item.title = title;
    item.type  = NZMenuItemTypeButton;
    item.action = action;
    return item;
}

+ (instancetype)switchWithTitle:(NSString *)title on:(BOOL)on toggle:(void(^)(BOOL))toggle {
    NZMenuItem *item  = [NZMenuItem new];
    item.title        = title;
    item.type         = NZMenuItemTypeSwitch;
    item.switchOn     = on;
    item.toggleAction = toggle;
    return item;
}

+ (instancetype)separator {
    NZMenuItem *item = [NZMenuItem new];
    item.type = NZMenuItemTypeSeparator;
    return item;
}

@end

// ──────────────────────────────────────────────────────────────────
#pragma mark - NZMenuTableCell (内部)

@interface NZMenuTableCell : UITableViewCell
@property (nonatomic, strong) UISwitch *toggle;
@property (nonatomic, copy)   void (^toggleAction)(BOOL);
@end

@implementation NZMenuTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor         = NZ_CELL_COLOR;
        self.textLabel.textColor     = NZ_TEXT_COLOR;
        self.textLabel.font          = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
        self.selectionStyle          = UITableViewCellSelectionStyleNone;
        UIView *sel                  = [UIView new];
        sel.backgroundColor          = [UIColor colorWithWhite:1 alpha:0.06];
        self.selectedBackgroundView  = sel;
    }
    return self;
}

- (void)addSwitch {
    self.toggle           = [[UISwitch alloc] init];
    self.toggle.onTintColor = NZ_ACCENT_COLOR;
    self.toggle.transform = CGAffineTransformMakeScale(0.80, 0.80);
    [self.toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    self.accessoryView = self.toggle;
}

- (void)switchChanged:(UISwitch *)sw {
    if (self.toggleAction) self.toggleAction(sw.isOn);
}

@end

// ──────────────────────────────────────────────────────────────────
#pragma mark - NZMenuPanelView (ドロワー本体)

@interface NZMenuPanelView : UIView <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) NSMutableArray<NZMenuItem *> *items;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy)   void (^onClose)(void);
@end

@implementation NZMenuPanelView

- (instancetype)initWithItems:(NSArray<NZMenuItem *> *)items {
    CGFloat totalHeight = kHeaderHeight + items.count * kRowHeight + 12;
    CGRect  frame = CGRectMake(0, 0, kMenuWidth, MIN(totalHeight, 480));
    self = [super initWithFrame:frame];
    if (self) {
        self.items           = [items mutableCopy];
        self.backgroundColor = NZ_BG_COLOR;
        self.layer.cornerRadius = kCornerRadius;
        self.clipsToBounds   = NO;
        self.layer.shadowColor   = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity = 0.45;
        self.layer.shadowOffset  = CGSizeMake(0, 6);
        self.layer.shadowRadius  = 16;
        [self buildHeader];
        [self buildTableView];
    }
    return self;
}

- (void)buildHeader {
    UIView *bar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kMenuWidth, 3)];
    bar.backgroundColor = NZ_ACCENT_COLOR;
    [self addSubview:bar];

    // マスクで角丸を復元（clipsToBounds=NO なので手動で上角だけ丸める）
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
        byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
              cornerRadii:CGSizeMake(kCornerRadius, kCornerRadius)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = maskPath.CGPath;
    bar.layer.mask = maskLayer;

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 3, kMenuWidth - 80, kHeaderHeight - 3)];
    title.text      = @"⚡ NezuTweak";
    title.textColor = NZ_TEXT_COLOR;
    title.font      = [UIFont systemFontOfSize:17 weight:UIFontWeightBold];
    [self addSubview:title];

    UILabel *sub = [[UILabel alloc] initWithFrame:CGRectMake(16, 30, kMenuWidth - 80, 20)];
    sub.text      = @"LINE Tweak  •  LC";
    sub.textColor = NZ_SUB_COLOR;
    sub.font      = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    [self addSubview:sub];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame     = CGRectMake(kMenuWidth - 50, 12, 36, 36);
    [close setTitle:@"✕" forState:UIControlStateNormal];
    close.tintColor = NZ_SUB_COLOR;
    close.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [close addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:close];

    UIView *div = [[UIView alloc] initWithFrame:CGRectMake(0, kHeaderHeight - 0.5, kMenuWidth, 0.5)];
    div.backgroundColor = [UIColor colorWithWhite:1 alpha:0.10];
    [self addSubview:div];
}

- (void)buildTableView {
    CGRect tvFrame = CGRectMake(0, kHeaderHeight, kMenuWidth,
                                self.bounds.size.height - kHeaderHeight);
    self.tableView = [[UITableView alloc] initWithFrame:tvFrame style:UITableViewStylePlain];
    self.tableView.dataSource     = self;
    self.tableView.delegate       = self;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorColor = [UIColor colorWithWhite:1 alpha:0.08];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 16, 0, 0);
    self.tableView.rowHeight      = kRowHeight;
    self.tableView.showsVerticalScrollIndicator = NO;

    // 下角を丸くする
    self.tableView.layer.cornerRadius   = kCornerRadius;
    self.tableView.layer.maskedCorners  =
        kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    self.tableView.clipsToBounds        = YES;
    [self addSubview:self.tableView];
}

- (void)closeTapped { if (self.onClose) self.onClose(); }

#pragma mark UITableViewDataSource / Delegate

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    NZMenuItem *item = self.items[ip.row];

    if (item.type == NZMenuItemTypeSeparator) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                       reuseIdentifier:nil];
        cell.backgroundColor        = NZ_BG_COLOR;
        cell.userInteractionEnabled = NO;
        UIView *line = [[UIView alloc] initWithFrame:CGRectMake(16, kRowHeight/2,
                                                               kMenuWidth - 32, 0.5)];
        line.backgroundColor = [UIColor colorWithWhite:1 alpha:0.12];
        [cell.contentView addSubview:line];
        return cell;
    }

    NZMenuTableCell *cell = [tv dequeueReusableCellWithIdentifier:@"NZCell"];
    if (!cell) cell = [[NZMenuTableCell alloc] initWithStyle:UITableViewCellStyleDefault
                                             reuseIdentifier:@"NZCell"];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.toggle        = nil;
    cell.toggleAction  = nil;
    cell.textLabel.text = item.title;

    if (item.type == NZMenuItemTypeSwitch) {
        [cell addSwitch];
        cell.toggle.on    = item.switchOn;
        cell.toggleAction = ^(BOOL on) {
            item.switchOn = on;
            if (item.toggleAction) item.toggleAction(on);
        };
    } else {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip {
    return kRowHeight;
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    NZMenuItem *item = self.items[ip.row];
    if (item.type == NZMenuItemTypeButton && item.action) item.action();
    [tv deselectRowAtIndexPath:ip animated:YES];
}

@end

// ──────────────────────────────────────────────────────────────────
#pragma mark - NZModMenuWindow

@interface NZModMenuWindow ()
@property (nonatomic, strong) NZMenuButton    *floatButton;
@property (nonatomic, strong) NZMenuPanelView *panel;
@property (nonatomic, strong) NSMutableArray<NZMenuItem *> *menuItems;
@property (nonatomic, assign) BOOL             isPanelVisible;
@end

@implementation NZModMenuWindow

// ─── LiveContainer 対応: UIWindowScene を安全に取得 ───────────────
+ (UIWindowScene *)activeWindowScene {
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] &&
            scene.activationState == UISceneActivationStateForegroundActive) {
            return (UIWindowScene *)scene;
        }
    }
    // フォールバック: 最初の UIWindowScene
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]]) {
            return (UIWindowScene *)scene;
        }
    }
    return nil;
}

+ (instancetype)sharedWindow {
    static NZModMenuWindow *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UIWindowScene *scene = [self activeWindowScene];
        if (scene) {
            instance = [[NZModMenuWindow alloc] initWithWindowScene:scene];
        } else {
            // LC環境で scene がまだない場合の最終フォールバック
            instance = [[NZModMenuWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        }
        // LC の UI ウィンドウより確実に上に表示
        instance.windowLevel            = UIWindowLevelAlert + 200;
        instance.backgroundColor        = UIColor.clearColor;
        instance.rootViewController     = [UIViewController new];
        instance.rootViewController.view.backgroundColor = UIColor.clearColor;
        instance.userInteractionEnabled = YES;
        // LC の multitask ウィンドウと干渉しないようにする
        if (@available(iOS 13.0, *)) {
            instance.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        }
    });
    return instance;
}

// ─── デフォルトメニュー項目 ───────────────────────────────────────
- (void)setupDefaultItems {
    __weak typeof(self) ws = self;

    [self addItem:[NZMenuItem buttonWithTitle:@"ℹ️  About NezuTweak" action:^{
        [ws showAbout];
    }]];
    [self addItem:[NZMenuItem separator]];
    [self addItem:[NZMenuItem switchWithTitle:@"🔇 既読スキップ (準備中)" on:NO toggle:^(BOOL on) {}]];
    [self addItem:[NZMenuItem switchWithTitle:@"👁  オンライン非表示 (準備中)" on:NO toggle:^(BOOL on) {}]];
    [self addItem:[NZMenuItem switchWithTitle:@"📸 ステルス閲覧 (準備中)" on:NO toggle:^(BOOL on) {}]];
}

// ─── 公開 API ─────────────────────────────────────────────────────
- (void)addItem:(NZMenuItem *)item { [self.menuItems addObject:item]; }

- (void)show {
    if (!self.menuItems) self.menuItems = [NSMutableArray array];
    if (self.menuItems.count == 0) [self setupDefaultItems];

    // LC環境で scene が後から確定する場合に再アタッチ
    if (@available(iOS 13.0, *)) {
        UIWindowScene *scene = [NZModMenuWindow activeWindowScene];
        if (scene && self.windowScene != scene) {
            self.windowScene = scene;
        }
    }

    [self makeKeyAndVisible];
    [self buildFloatButton];
    NSLog(@"[NezuTweak] 🎯 ModMenu visible");
}

// ─── フローティングボタン ─────────────────────────────────────────
- (void)buildFloatButton {
    if (self.floatButton) return;

    // セーフエリアを考慮した初期位置
    CGFloat screenW = UIScreen.mainScreen.bounds.size.width;
    CGFloat x = screenW - kButtonSize - 12;
    CGFloat y = 120;

    // ノッチ / Dynamic Island を避ける
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets insets = UIApplication.sharedApplication.keyWindow.safeAreaInsets;
        if (insets.top > 20) y = insets.top + 60;
    }

    self.floatButton = [[NZMenuButton alloc]
        initWithFrame:CGRectMake(x, y, kButtonSize, kButtonSize)];
    [self.floatButton addTarget:self action:@selector(floatButtonTapped)
               forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleDrag:)];
    [self.floatButton addGestureRecognizer:pan];

    [self.rootViewController.view addSubview:self.floatButton];
}

- (void)floatButtonTapped {
    self.isPanelVisible ? [self hidePanel] : [self showPanel];
}

// ─── パネル表示/非表示 ────────────────────────────────────────────
- (void)showPanel {
    if (self.panel) [self.panel removeFromSuperview];

    self.panel = [[NZMenuPanelView alloc] initWithItems:self.menuItems];
    __weak typeof(self) ws = self;
    self.panel.onClose = ^{ [ws hidePanel]; };

    CGFloat btnMidY = CGRectGetMidY(self.floatButton.frame);
    CGFloat px      = self.floatButton.frame.origin.x - kMenuWidth - 8;
    if (px < 8) px  = self.floatButton.frame.origin.x + kButtonSize + 8;
    CGFloat py      = btnMidY - self.panel.bounds.size.height / 2;
    py = MAX(py, 20);
    CGFloat maxY = UIScreen.mainScreen.bounds.size.height - self.panel.bounds.size.height - 20;
    py = MIN(py, maxY);

    self.panel.frame     = CGRectMake(px, py, kMenuWidth, self.panel.bounds.size.height);
    self.panel.alpha     = 0;
    self.panel.transform = CGAffineTransformMakeScale(0.92, 0.92);
    [self.rootViewController.view addSubview:self.panel];

    [UIView animateWithDuration:0.22 delay:0
         usingSpringWithDamping:0.78 initialSpringVelocity:0.5
                        options:0 animations:^{
        self.panel.alpha     = 1;
        self.panel.transform = CGAffineTransformIdentity;
    } completion:nil];

    self.isPanelVisible = YES;
}

- (void)hidePanel {
    [UIView animateWithDuration:0.18 animations:^{
        self.panel.alpha     = 0;
        self.panel.transform = CGAffineTransformMakeScale(0.90, 0.90);
    } completion:^(BOOL done) {
        [self.panel removeFromSuperview];
        self.panel = nil;
        self.isPanelVisible = NO;
    }];
}

// ─── ドラッグ & 端スナップ ────────────────────────────────────────
- (void)handleDrag:(UIPanGestureRecognizer *)pan {
    CGPoint delta = [pan translationInView:self.rootViewController.view];
    [pan setTranslation:CGPointZero inView:self.rootViewController.view];

    CGRect f     = self.floatButton.frame;
    f.origin.x  += delta.x;
    f.origin.y  += delta.y;

    CGFloat maxX = UIScreen.mainScreen.bounds.size.width  - kButtonSize - 4;
    CGFloat maxY = UIScreen.mainScreen.bounds.size.height - kButtonSize - 4;
    f.origin.x   = MAX(4, MIN(f.origin.x, maxX));
    f.origin.y   = MAX(40, MIN(f.origin.y, maxY));
    self.floatButton.frame = f;

    if (pan.state == UIGestureRecognizerStateEnded) {
        CGFloat cx     = CGRectGetMidX(f);
        CGFloat target = cx < UIScreen.mainScreen.bounds.size.width / 2 ? 4 : maxX;
        [UIView animateWithDuration:0.25 delay:0
             usingSpringWithDamping:0.75 initialSpringVelocity:0.3
                            options:0 animations:^{
            CGRect nf    = self.floatButton.frame;
            nf.origin.x  = target;
            self.floatButton.frame = nf;
        } completion:nil];
    }
}

// ─── About 表示 ───────────────────────────────────────────────────
- (void)showAbout {
    [self hidePanel];
    NZAboutViewController *vc  = [NZAboutViewController new];
    UINavigationController *nav = [[UINavigationController alloc]
        initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.rootViewController presentViewController:nav animated:YES completion:nil];
}

@end
