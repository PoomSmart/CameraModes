#import "../PS.h"



NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.CameraModes.plist";
CFStringRef const PreferencesNotification = CFSTR("com.PS.CameraModes.prefs");
NSString *const kEnabledModesKey = @"EnabledModes";
NSString *const kDisabledModesKey = @"DisabledModes";

// camera modes
typedef NS_ENUM(NSInteger, cameraMode) {
	cameraModePhoto,
	cameraModeVideo,
	cameraModeSlalom,
	cameraModePano,
	cameraModeSquare,
	cameraModeBW,
	cameraModeTimeLapse
};