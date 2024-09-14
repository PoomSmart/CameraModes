#import "Common.h"

BOOL tweakEnabled;
BOOL QRModeEnabled;

NSMutableArray *enabledModes;

/*
   Camera modes (iOS 9 - 14) : 5, 2, 1, 0, (6), 4, 3
        5 - Time-Lapse
        2 - Slo-mo
        1 - Video
        0 - Photo
        6 - Portrait
        4 - Square
        3 - Panorama
 */

 /*
   Camera modes (iOS 15+) : 5, 2, (7), 1, 0, (6), 4, 3
        5 - Time-Lapse
        2 - Slo-mo
        7 - Cinematic
        1 - Video
        0 - Photo
        6 - Portrait
        4 - Square
        3 - Panorama
 */

static NSMutableArray *modesHook(NSArray *modes) {
    NSMutableArray *newModes = [NSMutableArray arrayWithArray:modes];
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    NSMutableArray *enabledModes = [NSMutableArray arrayWithArray:prefs[kEnabledModesKey]];
    [enabledModes filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [newModes containsObject:evaluatedObject];
    }]];

    BOOL shouldUse = enabledModes.count > 0;
    return shouldUse ? enabledModes : newModes;
}

static NSInteger effectiveCameraMode(CAMViewfinderViewController *controller, NSInteger origMode){
    NSMutableArray *modes = [controller modesForModeDial:nil];
    if (modes.count == 0)
        return origMode;
    if ([modes containsObject:@(origMode)])
        return origMode;
    NSCAssert(modes.count != 0, @"There is no available camera mode.");
    return ((NSNumber *)modes[0]).intValue;
}

%hook CAMViewfinderViewController

- (NSMutableArray *)modesForModeDial:(id)arg1 {
    return modesHook(%orig);
}

- (void)changeToMode:(NSInteger)mode device:(NSInteger)device animated:(BOOL)animated {
    %orig(effectiveCameraMode(self, mode), device, animated);
}

%end

static void reloadSettings(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo){
    CFPreferencesAppSynchronize(CFSTR("com.ps.cameramodes"));
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    id val = prefs[@"tweakEnabled"];
    tweakEnabled = val ? [val boolValue] : YES;
}

%ctor {
    reloadSettings(NULL, NULL, NULL, NULL, NULL);
    if (!tweakEnabled) return;
    %init;
}
