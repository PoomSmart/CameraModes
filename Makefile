GO_EASY_ON_ME = 1
DEBUG = 0
PACKAGE_VERSION = 1.1.4

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = CameraModes
CameraModes_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = CameraModesSettings
CameraModesSettings_FILES = CameraModesPreferenceController.m
CameraModesSettings_INSTALL_PATH = /Library/PreferenceBundles
CameraModesSettings_PRIVATE_FRAMEWORKS = Preferences
CameraModesSettings_LIBRARIES = MobileGestalt
CameraModesSettings_FRAMEWORKS = Social

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/CameraModes.plist$(ECHO_END)
	$(ECHO_NOTHING)find $(THEOS_STAGING_DIR) -name .DS_Store | xargs rm -rf$(ECHO_END)