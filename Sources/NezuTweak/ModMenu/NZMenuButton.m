// NZMenuButton.m
// NezuTweak — フローティングドラッグボタン描画

#import "NZMenuButton.h"

@implementation NZMenuButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupAppearance];
    }
    return self;
}

- (void)setupAppearance {
    self.backgroundColor    = UIColor.clearColor;
    self.layer.cornerRadius = self.bounds.size.width / 2;
    self.clipsToBounds      = NO;

    // 影
    self.layer.shadowColor   = UIColor.blackColor.CGColor;
    self.layer.shadowOpacity = 0.40;
    self.layer.shadowOffset  = CGSizeMake(0, 4);
    self.layer.shadowRadius  = 10;

    // グラデーション背景
    CAGradientLayer *grad  = [CAGradientLayer layer];
    grad.frame             = self.bounds;
    grad.cornerRadius      = self.bounds.size.width / 2;
    grad.colors            = @[
        (__bridge id)[UIColor colorWithRed:0.00 green:0.85 blue:0.50 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithRed:0.00 green:0.60 blue:0.90 alpha:1.0].CGColor
    ];
    grad.startPoint = CGPointMake(0, 0);
    grad.endPoint   = CGPointMake(1, 1);
    grad.name       = @"nzGrad";
    [self.layer insertSublayer:grad atIndex:0];

    // ⚡アイコン
    UILabel *icon       = [[UILabel alloc] initWithFrame:self.bounds];
    icon.text           = @"⚡";
    icon.textAlignment  = NSTextAlignmentCenter;
    icon.font           = [UIFont systemFontOfSize:24];
    icon.userInteractionEnabled = NO;
    [self addSubview:icon];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    // グラデーションレイヤーのリサイズ
    for (CALayer *layer in self.layer.sublayers) {
        if ([layer.name isEqualToString:@"nzGrad"]) {
            layer.frame = self.bounds;
        }
    }
    self.layer.cornerRadius = self.bounds.size.width / 2;
}

// タップのハイライト
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [UIView animateWithDuration:0.12 animations:^{
        self.transform = highlighted
            ? CGAffineTransformMakeScale(0.90, 0.90)
            : CGAffineTransformIdentity;
        self.alpha = highlighted ? 0.85 : 1.0;
    }];
}

@end
