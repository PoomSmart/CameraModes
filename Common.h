#import "../PS.h"

NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.CameraModes.plist";
CFStringRef const PreferencesNotification = CFSTR("com.PS.CameraModes.prefs");
NSString *const kEnabledModesKey = @"EnabledModes";
NSString *const kDisabledModesKey = @"DisabledModes";

typedef NS_ENUM(NSInteger, cameraMode) {
  cameraModePhoto,
  cameraModeVideo,
  cameraaModeSalom,
  cameraModePano,
  cameraModeSquare,
  cameraModeBW,
  cameraModeTimeLapse
};