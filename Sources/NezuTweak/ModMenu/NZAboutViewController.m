// NZAboutViewController.m
// NezuTweak — About パネル実装

#import "NZAboutViewController.h"

// ─── カラー ──────────────────────────────────────────────────────
#define NZ_DARK      [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0]
#define NZ_CARD      [UIColor colorWithRed:0.13 green:0.13 blue:0.18 alpha:1.0]
#define NZ_ACCENT    [UIColor colorWithRed:0.00 green:0.80 blue:0.47 alpha:1.0]
#define NZ_ACCENT2   [UIColor colorWithRed:0.00 green:0.60 blue:0.90 alpha:1.0]
#define NZ_TEXT      [UIColor whiteColor]
#define NZ_SUB       [UIColor colorWithWhite:0.60 alpha:1.0]
#define NZ_SEP       [UIColor colorWithWhite:1.0  alpha:0.08]

// ─── 情報テーブルのモデル ─────────────────────────────────────────
@interface NZInfoRow : NSObject
@property (nonatomic, copy) NSString *icon;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *value;
+ (instancetype)icon:(NSString *)icon label:(NSString *)label value:(NSString *)value;
@end

@implementation NZInfoRow
+ (instancetype)icon:(NSString *)icon label:(NSString *)label value:(NSString *)value {
    NZInfoRow *r = [NZInfoRow new];
    r.icon = icon; r.label = label; r.value = value;
    return r;
}
@end

// ─── カードビュー ─────────────────────────────────────────────────
@interface NZCardView : UIView
@end
@implementation NZCardView
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor      = NZ_CARD;
        self.layer.cornerRadius   = 14;
        self.layer.shadowColor    = UIColor.blackColor.CGColor;
        self.layer.shadowOpacity  = 0.25;
        self.layer.shadowOffset   = CGSizeMake(0, 4);
        self.layer.shadowRadius   = 10;
    }
    return self;
}
@end

// ─── NZAboutViewController ────────────────────────────────────────
@interface NZAboutViewController ()
@property (nonatomic, strong) UIScrollView *scroll;
@property (nonatomic, strong) NSArray<NZInfoRow *> *infoRows;
@end

@implementation NZAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"About";
    self.view.backgroundColor = NZ_DARK;

    // ナビゲーションバーの外観
    UINavigationBarAppearance *app = [UINavigationBarAppearance new];
    [app configureWithOpaqueBackground];
    app.backgroundColor         = NZ_DARK;
    app.titleTextAttributes     = @{NSForegroundColorAttributeName: NZ_TEXT};
    self.navigationController.navigationBar.standardAppearance    = app;
    self.navigationController.navigationBar.scrollEdgeAppearance  = app;
    self.navigationController.navigationBar.tintColor             = NZ_ACCENT;

    // 閉じるボタン
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemClose
        target:self action:@selector(closeTapped)];

    // 情報行データ
    self.infoRows = @[
        [NZInfoRow icon:@"📦" label:@"Tweak名"     value:@"NezuTweak"],
        [NZInfoRow icon:@"🔢" label:@"バージョン"   value:@"0.1.0"],
        [NZInfoRow icon:@"🎯" label:@"対象アプリ"   value:@"LINE (jp.naver.line)"],
        [NZInfoRow icon:@"📱" label:@"最小iOS"      value:@"iOS 14.0"],
        [NZInfoRow icon:@"⚙️" label:@"ビルド"       value:@"Theos + Logos"],
        [NZInfoRow icon:@"👤" label:@"作者"         value:@"nezu"],
    ];

    [self buildUI];
}

- (void)buildUI {
    self.scroll = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scroll.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scroll.alwaysBounceVertical = YES;
    [self.view addSubview:self.scroll];

    CGFloat w   = self.view.bounds.size.width;
    CGFloat pad = 20;
    CGFloat y   = 24;

    // ─── ロゴカード ──────────────────────────────────────────────
    NZCardView *logoCard = [[NZCardView alloc] initWithFrame:CGRectMake(pad, y, w - pad*2, 140)];
    [self.scroll addSubview:logoCard];

    // グラデーション円形アイコン
    UIView *iconCircle = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 72, 72)];
    iconCircle.center = CGPointMake(logoCard.bounds.size.width / 2, 50);
    iconCircle.layer.cornerRadius = 36;
    iconCircle.clipsToBounds = YES;

    CAGradientLayer *grad  = [CAGradientLayer layer];
    grad.frame             = iconCircle.bounds;
    grad.colors            = @[
        (__bridge id)[UIColor colorWithRed:0.00 green:0.85 blue:0.50 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.00 green:0.60 blue:0.90 alpha:1.0].CGColor
    ];
    grad.startPoint  = CGPointMake(0, 0);
    grad.endPoint    = CGPointMake(1, 1);
    [iconCircle.layer addSublayer:grad];

    UILabel *emoji = [[UILabel alloc] initWithFrame:iconCircle.bounds];
    emoji.text = @"⚡";
    emoji.textAlignment = NSTextAlignmentCenter;
    emoji.font = [UIFont systemFontOfSize:34];
    [iconCircle addSubview:emoji];
    [logoCard addSubview:iconCircle];

    // タイトル
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 95, logoCard.bounds.size.width, 24)];
    titleLabel.text          = @"NezuTweak";
    titleLabel.textColor     = NZ_TEXT;
    titleLabel.font          = [UIFont systemFontOfSize:18 weight:UIFontWeightBold];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [logoCard addSubview:titleLabel];

    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 118, logoCard.bounds.size.width, 18)];
    subLabel.text          = @"LINE Tweak with Mod Menu";
    subLabel.textColor     = NZ_SUB;
    subLabel.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    subLabel.textAlignment = NSTextAlignmentCenter;
    [logoCard addSubview:subLabel];

    y += 140 + 16;

    // ─── 情報カード ──────────────────────────────────────────────
    UILabel *infoHeader = [self sectionHeader:@"TWEAK INFO"];
    infoHeader.frame = CGRectMake(pad + 4, y, w - pad*2, 22);
    [self.scroll addSubview:infoHeader];
    y += 26;

    CGFloat rowH   = 52;
    CGFloat cardH  = rowH * self.infoRows.count;
    NZCardView *infoCard = [[NZCardView alloc] initWithFrame:CGRectMake(pad, y, w - pad*2, cardH)];
    [self.scroll addSubview:infoCard];

    for (NSInteger i = 0; i < self.infoRows.count; i++) {
        NZInfoRow *row = self.infoRows[i];
        CGFloat ry = i * rowH;

        // アイコン
        UILabel *iconL = [[UILabel alloc] initWithFrame:CGRectMake(14, ry, 28, rowH)];
        iconL.text = row.icon;
        iconL.font = [UIFont systemFontOfSize:18];
        iconL.textAlignment = NSTextAlignmentCenter;
        [infoCard addSubview:iconL];

        // ラベル
        UILabel *labelL = [[UILabel alloc] initWithFrame:CGRectMake(48, ry, 120, rowH)];
        labelL.text      = row.label;
        labelL.textColor = NZ_SUB;
        labelL.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
        [infoCard addSubview:labelL];

        // 値
        UILabel *valueL = [[UILabel alloc] initWithFrame:CGRectMake(0, ry, infoCard.bounds.size.width - 16, rowH)];
        valueL.text          = row.value;
        valueL.textColor     = NZ_TEXT;
        valueL.font          = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        valueL.textAlignment = NSTextAlignmentRight;
        [infoCard addSubview:valueL];

        // 区切り線（最後の行以外）
        if (i < self.infoRows.count - 1) {
            UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(48, ry + rowH - 0.5, infoCard.bounds.size.width - 48, 0.5)];
            sep.backgroundColor = NZ_SEP;
            [infoCard addSubview:sep];
        }
    }
    y += cardH + 16;

    // ─── 機能リストカード ─────────────────────────────────────────
    UILabel *featHeader = [self sectionHeader:@"機能 (開発中)"];
    featHeader.frame = CGRectMake(pad + 4, y, w - pad*2, 22);
    [self.scroll addSubview:featHeader];
    y += 26;

    NSArray *features = @[
        @[@"🔇", @"既読スキップ",         @"準備中"],
        @[@"👁",  @"オンライン非表示",     @"準備中"],
        @[@"📸",  @"ステルス閲覧",         @"準備中"],
        @[@"💬",  @"送信取消メッセージ復元", @"準備中"],
    ];

    NZCardView *featCard = [[NZCardView alloc] initWithFrame:CGRectMake(pad, y, w - pad*2, rowH * features.count)];
    [self.scroll addSubview:featCard];

    for (NSInteger i = 0; i < features.count; i++) {
        NSArray *feat = features[i];
        CGFloat ry = i * rowH;

        UILabel *iconL = [[UILabel alloc] initWithFrame:CGRectMake(14, ry, 28, rowH)];
        iconL.text = feat[0];
        iconL.font = [UIFont systemFontOfSize:18];
        iconL.textAlignment = NSTextAlignmentCenter;
        [featCard addSubview:iconL];

        UILabel *nameL = [[UILabel alloc] initWithFrame:CGRectMake(48, ry, 180, rowH)];
        nameL.text      = feat[1];
        nameL.textColor = NZ_TEXT;
        nameL.font      = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
        [featCard addSubview:nameL];

        // バッジ
        UILabel *badge = [[UILabel alloc] init];
        badge.text            = feat[2];
        badge.font            = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
        badge.textColor       = NZ_ACCENT;
        badge.backgroundColor = [NZ_ACCENT colorWithAlphaComponent:0.15];
        badge.layer.cornerRadius = 6;
        badge.clipsToBounds   = YES;
        badge.textAlignment   = NSTextAlignmentCenter;
        [badge sizeToFit];
        badge.frame = CGRectMake(
            featCard.bounds.size.width - badge.bounds.size.width - 24,
            ry + (rowH - 22) / 2,
            badge.bounds.size.width + 12,
            22
        );
        [featCard addSubview:badge];

        if (i < features.count - 1) {
            UIView *sep = [[UIView alloc] initWithFrame:CGRectMake(48, ry + rowH - 0.5, featCard.bounds.size.width - 48, 0.5)];
            sep.backgroundColor = NZ_SEP;
            [featCard addSubview:sep];
        }
    }
    y += rowH * features.count + 16;

    // ─── 免責事項 ─────────────────────────────────────────────────
    UILabel *disclaimerHeader = [self sectionHeader:@"注意事項"];
    disclaimerHeader.frame = CGRectMake(pad + 4, y, w - pad*2, 22);
    [self.scroll addSubview:disclaimerHeader];
    y += 26;

    NZCardView *disclaimerCard = [[NZCardView alloc] initWithFrame:CGRectMake(pad, y, w - pad*2, 80)];
    [self.scroll addSubview:disclaimerCard];

    UILabel *disclaimerLabel = [[UILabel alloc] initWithFrame:CGRectInset(disclaimerCard.bounds, 14, 12)];
    disclaimerLabel.text          = @"本Tweakは教育・研究目的のみです。LINEの利用規約に違反する使用は禁止されています。使用は自己責任でお願いします。";
    disclaimerLabel.textColor     = NZ_SUB;
    disclaimerLabel.font          = [UIFont systemFontOfSize:12 weight:UIFontWeightRegular];
    disclaimerLabel.numberOfLines = 0;
    [disclaimerCard addSubview:disclaimerLabel];
    y += 80 + 32;

    self.scroll.contentSize = CGSizeMake(w, y);
}

// ─── ヘルパー ─────────────────────────────────────────────────────
- (UILabel *)sectionHeader:(NSString *)text {
    UILabel *l    = [UILabel new];
    l.text        = text;
    l.textColor   = NZ_SUB;
    l.font        = [UIFont systemFontOfSize:11 weight:UIFontWeightSemibold];
    return l;
}

- (void)closeTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
