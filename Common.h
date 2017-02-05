#import "../PS.h"

NSString *PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.CameraModes.plist";
CFStringRef PreferencesNotification = CFSTR("com.PS.CameraModes.prefs");
NSString *kEnabledModesKey = @"EnabledModes";
NSString *kDisabledModesKey = @"DisabledModes";

// camera modes
typedef NS_ENUM(int, cameraMode) {
	cameraModePhoto,
	cameraModeVideo,
	cameraModeSlalom,
	cameraModePano,
	cameraModeSquare,
	cameraModeBW,
	cameraModeTimeLapse
};
#define cameraModePortrait cameraModeBW
