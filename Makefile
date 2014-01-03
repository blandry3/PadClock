TARGET := iphone:7.0:2.0
ARCHS := armv6 arm64

include theos/makefiles/common.mk

TWEAK_NAME = PadClock
PadClock_FILES = Tweak.xm
PadClock_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += padclockprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "killall MobileTimer"