#import "Common.h"

@interface PLCameraController : NSObject
+ (PLCameraController *)sharedInstance;
- (NSMutableArray *)supportedCameraModes;
@end

@interface CAMCaptureController : NSObject
+ (CAMCaptureController *)sharedInstance;
- (NSMutableArray *)supportedCameraModes;
@end

BOOL tweakEnabled;

NSMutableArray *enabledModes;

extern int __UIImagePickerControllerCameraCaptureMode;

// mode : 6, 2, 1, 0, 4, 3

static NSMutableArray *modesHook(NSArray *modes)
{
	NSMutableArray *newModes = [NSMutableArray arrayWithArray:modes];
	if (!tweakEnabled)
		return newModes;
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	NSArray *enabledModes = prefs[kEnabledModesKey];
	NSArray *disabledModes = prefs[kDisabledModesKey];
	if (enabledModes == nil || disabledModes == nil)
		return newModes;
	NSMutableArray *modesToDelete = [NSMutableArray array];
	for (NSNumber *mode in disabledModes) {
		if ([newModes containsObject:mode])
			[modesToDelete addObject:mode];
	}
	if (modesToDelete.count > 0) {
		for (NSNumber *mode in modesToDelete) {
			[newModes removeObject:mode];
		}
	}
	
	for (NSUInteger i = 0; i < enabledModes.count; i++) {
		NSNumber *modeFromPref = enabledModes[i];
		NSNumber *modeHere = newModes[i];
		if (modeFromPref.intValue != modeHere.intValue) {
			for (NSUInteger j = 0; j < newModes.count; j++) {
				NSNumber *modeHere2 = newModes[j];
				if (modeHere2.intValue == modeFromPref.intValue)
					[newModes exchangeObjectAtIndex:i withObjectAtIndex:j];
			}
		}
	}
	
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
