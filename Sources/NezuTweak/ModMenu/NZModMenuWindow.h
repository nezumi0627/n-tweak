// NZModMenuWindow.h
// NezuTweak — LINE ModMenu
// 浮遊ドラッグ可能なモッドメニューウィンドウ

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// メニュー項目の種類
typedef NS_ENUM(NSInteger, NZMenuItemType) {
    NZMenuItemTypeButton,   ///< タップ可能なボタン
    NZMenuItemTypeSwitch,   ///< ON/OFF トグル
    NZMenuItemTypeSeparator ///< 区切り線
};

/// メニュー項目モデル
@interface NZMenuItem : NSObject
@property (nonatomic, copy)   NSString        *title;
@property (nonatomic, assign) NZMenuItemType   type;
@property (nonatomic, copy, nullable) void (^action)(void);          ///< ボタン用
@property (nonatomic, copy, nullable) void (^toggleAction)(BOOL on); ///< スイッチ用
@property (nonatomic, assign) BOOL switchOn;
+ (instancetype)buttonWithTitle:(NSString *)title action:(void(^)(void))action;
+ (instancetype)switchWithTitle:(NSString *)title on:(BOOL)on toggle:(void(^)(BOOL))toggle;
+ (instancetype)separator;
@end

/// メインのModMenuウィンドウ
@interface NZModMenuWindow : UIWindow
+ (instancetype)sharedWindow;
- (void)show;
- (void)addItem:(NZMenuItem *)item;
@end

NS_ASSUME_NONNULL_END
