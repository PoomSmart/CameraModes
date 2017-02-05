#import "Common.h"

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

/*
Camera modes (iOS 10): 5, 2, 1, 0, 6, 4, 3
	Almost all are the same, but 5 now represents the portrait mode
*/

static NSMutableArray *modesHook(NSArray *modes)
{
	if (!tweakEnabled)
		return (NSMutableArray *)modes;
	NSMutableArray *newModes = [NSMutableArray arrayWithArray:modes];
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	NSMutableArray *enabledModes = [NSMutableArray arrayWithArray:prefs[kEnabledModesKey]];

	// QRMode compatiblity - remove QRMode mode if QRMode is not installed anymore and/or not enabled
	if (![modes containsObject:@(cameraModeBW)])
		[enabledModes removeObject:@(cameraModeBW)];

	BOOL shouldUse = enabledModes.count > 0;
	return shouldUse ? enabledModes : newModes;
}

static NSInteger effectiveCameraMode(NSInteger origMode)
{
	NSObject <cameraControllerDelegate> *cameraInstance = %c(CAMCaptureController) ? (CAMCaptureController *)[%c(CAMCaptureController) sharedInstance] : (PLCameraController *)[%c(PLCameraController) sharedInstance];
	NSMutableArray *modes = [cameraInstance supportedCameraModes];
	if (modes.count == 0)
		return origMode;
	if ([modes containsObject:@(origMode)])
		return origMode;
	NSCAssert(modes.count != 0, @"There is no available camera mode.");
	return ((NSNumber *)modes[0]).intValue;
}

static NSInteger effectiveCameraMode2(CAMViewfinderViewController *controller, NSInteger origMode)
{
	NSMutableArray *modes = [controller modesForModeDial:nil];
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
	%orig(effectiveCameraMode(mode), device);
}

%end

%hook PLCameraView

- (void)setCameraMode:(NSInteger)mode
{
	%orig(effectiveCameraMode(mode));
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
	%orig(effectiveCameraMode(mode), device, force);
}

%end

%hook CAMCameraView

- (void)setCameraMode:(NSInteger)mode
{
	%orig(effectiveCameraMode(mode));
}

%end

%end

%group iOS9

%hook CAMViewfinderViewController

- (NSMutableArray *)modesForModeDial:(id)arg1
{
	return modesHook(%orig);
}

- (void)changeToMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated
{
	%orig(effectiveCameraMode2(self, mode), device, animated);
}

%end

%end

static void reloadSettings(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	CFPreferencesAppSynchronize(CFSTR("com.PS.CameraModes"));
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	id val = prefs[@"tweakEnabled"];
	tweakEnabled = val ? [val boolValue] : YES;
}

%ctor
{
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadSettings, PreferencesNotification, NULL, CFNotificationSuspensionBehaviorCoalesce);
	reloadSettings(NULL, NULL, NULL, NULL, NULL);
	if (isiOS9Up) {
		%init(iOS9);
	} else if (isiOS8) {
		%init(iOS8);
	} else {
		%init(iOS7);
	}
}
