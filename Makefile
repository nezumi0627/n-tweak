ARCHS = arm64
TARGET = iphone:clang:16.5:14.0

# ─────────────────────────────────────────────────────────────────
# LiveContainer 向け .dylib ビルド
# .deb / TweakLoader は使用しない
# LC_ID_DYLIB は Theos が dylib target で自動挿入する
# ─────────────────────────────────────────────────────────────────

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = NezuTweak

NezuTweak_FILES  = Sources/NezuTweak/Tweak.m
NezuTweak_FILES += Sources/NezuTweak/ModMenu/NZModMenuWindow.m
NezuTweak_FILES += Sources/NezuTweak/ModMenu/NZAboutViewController.m
NezuTweak_FILES += Sources/NezuTweak/ModMenu/NZMenuButton.m

NezuTweak_CFLAGS     = -fobjc-arc \
                        -I$(THEOS_PROJECT_DIR)/Sources/NezuTweak \
                        -DNZ_LIVECONTAINER=1

NezuTweak_FRAMEWORKS = UIKit Foundation CoreGraphics ObjectiveC

# ElleKit / CydiaSubstrate には依存しない (LC環境では存在しないため)
# フックは純粋な ObjC runtime API で行う
NezuTweak_LIBRARIES  =

include $(THEOS)/makefiles/library.mk

# ─── 後処理: LC_ID_DYLIB を正規化 ──────────────────────────────────
after-all::
	install_name_tool -id @loader_path/NezuTweak.dylib \
		$(THEOS_OBJ_DIR)/NezuTweak.dylib 2>/dev/null || true
