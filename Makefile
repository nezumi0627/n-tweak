ARCHS = arm64
TARGET = iphone:clang:16.5:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NezuTweak

NezuTweak_FILES  = Sources/NezuTweak/Tweak.x
NezuTweak_FILES += Sources/NezuTweak/ModMenu/NZModMenuWindow.m
NezuTweak_FILES += Sources/NezuTweak/ModMenu/NZAboutViewController.m
NezuTweak_FILES += Sources/NezuTweak/ModMenu/NZMenuButton.m

NezuTweak_CFLAGS     = -fobjc-arc -I$(THEOS_PROJECT_DIR)/Sources/NezuTweak
NezuTweak_FRAMEWORKS = UIKit Foundation CoreGraphics

include $(THEOS)/makefiles/tweak.mk
