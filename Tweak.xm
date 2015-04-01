#import "Common.h"
#import <dlfcn.h>

BOOL tweakEnabled;
BOOL QRModeEnabled;

NSMutableArray *enabledModes;

/*
Camera modes : 6, 2, 1, 0, 4, 3, (5)
	6 - Time-Lapse
	2 - Slo-mo
	1 - Video
	0 - Photo
	4 - Square
	3 - Panorama
	5 - Unknown (is B&W but does nothing) (This mode is used by QR Mode tweak)
*/

static NSMutableArray *modesHook(NSArray *modes)
{
	NSMutableArray *newModes = [NSMutableArray arrayWithArray:modes];
	if (!tweakEnabled)
		return newModes;
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	NSMutableArray *enabledModes = [NSMutableArray arrayWithArray:prefs[kEnabledModesKey]];

	// QRMode compatiblity - remove QRMode mode if QRMode is not installed anymore and/or not enabled
	if (![modes containsObject:@(cameraModeBW)])
		[enabledModes removeObject:@(cameraModeBW)];

	BOOL shouldUse = enabledModes.count > 0;
	return shouldUse ? enabledModes : newModes;
}

static NSInteger effectiveCameraMode(NSMutableArray *modes, NSInteger origMode)
{
	if (modes.count == 0)
		return origMode;
	if ([modes containsObject:@(origMode)])
		return origMode;
	NSCAssert(modes.count != 0, @"There is no available camera mode.");
	return ((NSNumber *)modes[0]).intValue;
}

%group iOS7

%hook PLCameraController

- (void)_setSupportedCameraModes:(NSArray *)modes
{
	%orig(modesHook(modes));
}

- (void)_setCameraMode:(NSInteger)mode cameraDevice:(NSInteger)device
{
	%orig(effectiveCameraMode([self supportedCameraModes], mode), device);
}

%end

%hook PLCameraView

- (void)setCameraMode:(NSInteger)mode
{
	%orig(effectiveCameraMode([(PLCameraController *)[objc_getClass("PLCameraController") sharedInstance] supportedCameraModes], mode));
}

%end

%end

%group iOS8

%hook CAMCaptureController

- (void)_setSupportedCameraModes:(NSArray *)modes
{
	%orig(modesHook(modes));
}

- (void)_setCameraMode:(NSInteger)mode cameraDevice:(NSInteger)device forceConfigure:(BOOL)force
{
	%orig(effectiveCameraMode([self supportedCameraModes], mode), device, force);
}

%end

%hook CAMCameraView

- (void)setCameraMode:(NSInteger)mode
{
	NSInteger effectiveMode = effectiveCameraMode([(CAMCaptureController *)[objc_getClass("CAMCaptureController") sharedInstance] supportedCameraModes], mode);
	%orig(effectiveMode);
}

%end

%end

static void reloadSettings(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	CFPreferencesAppSynchronize(CFSTR("com.PS.CameraModes"));
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	tweakEnabled = prefs[@"tweakEnabled"] ? [prefs[@"tweakEnabled"] boolValue] : YES;
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
