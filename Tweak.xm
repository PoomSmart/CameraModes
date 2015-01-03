#import "../PS.h"

NSString *const PREF_PATH = @"/var/mobile/Library/Preferences/com.PS.CameraModes.plist";
CFStringRef const PreferencesNotification = CFSTR("com.PS.CameraModes.prefs");

@interface PLCameraController : NSObject
+ (PLCameraController *)sharedInstance;
- (NSMutableArray *)supportedCameraModes;
@end

@interface CAMCaptureController : NSObject
+ (CAMCaptureController *)sharedInstance;
- (NSMutableArray *)supportedCameraModes;
@end

BOOL tweakEnabled;
BOOL timelapseEnabled;
BOOL slomoEnabled;
BOOL videoEnabled;
BOOL photoEnabled;
BOOL squareEnabled;
BOOL panoEnabled;

extern int __UIImagePickerControllerCameraCaptureMode;

// mode : 6, 2, 1, 0, 4, 3

static NSMutableArray *modesHook(NSArray *modes)
{
	NSMutableArray *newModes = [NSMutableArray arrayWithArray:modes];
	if (!tweakEnabled)
		return newModes;
	if (!timelapseEnabled)
		[newModes removeObject:@6];
	if (!slomoEnabled)
		[newModes removeObject:@2];
	if (!videoEnabled)
		[newModes removeObject:@1];
	if (!photoEnabled)
		[newModes removeObject:@0];
	if (!squareEnabled)
		[newModes removeObject:@4];
	if (!panoEnabled)
		[newModes removeObject:@3];
	//[newModes addObject:@5];
	return newModes;
}

static int effectiveCameraMode(NSMutableArray *modes, int origMode)
{
	if (modes == nil || [modes containsObject:@(origMode)])
		return origMode;
	NSCAssert(modes.count != 0, @"There is no available camera modes.");
	return ((NSNumber *)modes[0]).intValue;
}

%group iOS7

%hook PLCameraController

- (void)_setSupportedCameraModes:(NSArray *)modes
{
	%orig(modesHook(modes));
}

- (void)setCameraMode:(int)mode device:(int)device
{
	%orig(effectiveCameraMode([self supportedCameraModes], mode), device);
}

%end

%hook PLCameraView

- (void)setCameraMode:(int)mode
{
	%orig(effectiveCameraMode([[objc_getClass("PLCameraController") sharedInstance] supportedCameraModes], mode));
}

%end

%end

%group iOS8

%hook CAMCaptureController

- (void)_setSupportedCameraModes:(NSArray *)modes
{
	%orig(modesHook(modes));
}

- (void)setCameraMode:(int)mode device:(int)device
{
	%orig(effectiveCameraMode([self supportedCameraModes], mode), device);
}

%end

%hook CAMCameraView

- (void)setCameraMode:(int)mode
{
	%orig(effectiveCameraMode([[objc_getClass("CAMCaptureController") sharedInstance] supportedCameraModes], mode));
}

%end

%end

static void reloadSettings(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	CFPreferencesAppSynchronize(CFSTR("com.PS.CameraModes"));
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	#define BoolOpt(option) \
		option = prefs[[NSString stringWithUTF8String:#option]] ? [prefs[[NSString stringWithUTF8String:#option]] boolValue] : YES;
	BoolOpt(tweakEnabled)
	BoolOpt(timelapseEnabled)
	BoolOpt(slomoEnabled)
	BoolOpt(videoEnabled)
	BoolOpt(photoEnabled)
	BoolOpt(squareEnabled)
	BoolOpt(panoEnabled)
}

%ctor
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadSettings, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings(NULL, NULL, NULL, NULL, NULL);
	if (isiOS8Up) {
		%init(iOS8);
	} else {
		%init(iOS7);
	}
  	[pool drain];
}
