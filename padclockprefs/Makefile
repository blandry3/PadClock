TARGET := iphone:7.0:2.0
ARCHS := armv6 arm64

include theos/makefiles/common.mk

BUNDLE_NAME = PadClockPrefs
PadClockPrefs_FILES = PadClockPrefs.mm
PadClockPrefs_INSTALL_PATH = /Library/PreferenceBundles
PadClockPrefs_FRAMEWORKS = UIKit
PadClockPrefs_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/PadClockPrefs.plist$(ECHO_END)
