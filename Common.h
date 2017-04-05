#import "../PS.h"

NSString *PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.CameraModes.plist";
CFStringRef PreferencesNotification = CFSTR("com.PS.CameraModes.prefs");
NSString *kEnabledModesKey = @"EnabledModes";
NSString *kDisabledModesKey = @"DisabledModes";

// camera modes
// pre-iOS 10
typedef NS_ENUM (int, cameraMode) {
    cameraModePhoto = 0,
    cameraModeVideo,
    cameraModeSlalom,
    cameraModePano,
    cameraModeSquare,
    cameraModeBW,
    cameraModeTimeLapse
};

// iOS 10
typedef NS_ENUM (int, cameraMode2) {
    cameraModePhoto2 = 0,
    cameraModeVideo2,
    cameraModeSlalom2,
    cameraModePano2,
    cameraModeSquare2,
    cameraModeTimeLapse2,
    cameraModePortrait2
};
