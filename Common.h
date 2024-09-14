#define UNRESTRICTED_AVAILABILITY
#import <PSHeader/CameraApp/CameraApp.h>
#import <PSHeader/CameraMacros.h>
#import <PSHeader/Misc.h>

#define PREF_PATH ROOT_PATH_NS(@"/var/mobile/Library/Preferences/com.ps.cameramodes.plist")
NSString *kEnabledModesKey = @"EnabledModes";
NSString *kDisabledModesKey = @"DisabledModes";

typedef NS_ENUM (int, cameraMode) {
    cameraModePhoto = 0,
    cameraModeVideo,
    cameraModeSlalom,
    cameraModePano,
    cameraModeSquare,
    cameraModeTimeLapse,
    cameraModePortrait,
    cameraModeCinematic
};
