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
	//NSLog(@"%@", enabledModes);
	return shouldUse ? enabledModes : newModes;
}

static NSObject <cameraControllerDelegate> *cameraInstance()
{
	if (%c(CAMCaptureController))
		return (CAMCaptureController *)[%c(CAMCaptureController) sharedInstance];
	return (PLCameraController *)[%c(PLCameraController) sharedInstance];
}

static int effectiveCameraMode(int origMode)
{
	NSMutableArray *modes = [cameraInstance() supportedCameraModes];
	if (modes.count == 0)
		return origMode;
	if ([modes containsObject:@(origMode)])
		return origMode;
	NSCAssert(modes.count != 0, @"There is no available camera mode.");
	return ((NSNumber *)modes[0]).intValue;
}

static int effectiveCameraMode2(CAMViewfinderViewController *controller, int origMode)
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

- (void)_setCameraMode:(int)mode cameraDevice:(int)device
{
	%orig(effectiveCameraMode(mode), device);
}

%end

%hook PLCameraView

- (void)setCameraMode:(int)mode
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

- (void)_setCameraMode:(int)mode cameraDevice:(int)device forceConfigure:(BOOL)force
{
	%orig(effectiveCameraMode(mode), device, force);
}

%end

%hook CAMCameraView

- (void)setCameraMode:(int)mode
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

- (void)changeToMode:(int)mode device:(int)device animated:(BOOL)animated
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