#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <dlfcn.h>
#import "../PS.h"

@interface CameraModesPreferenceController : PSListController
@property (nonatomic, retain) PSSpecifier *timelapseSpec;
@property (nonatomic, retain) PSSpecifier *slomoSpec;
@property (nonatomic, retain) PSSpecifier *videoSpec;
@property (nonatomic, retain) PSSpecifier *photoSpec;
@property (nonatomic, retain) PSSpecifier *squareSpec;
@property (nonatomic, retain) PSSpecifier *panoSpec;
@end

static BOOL (*MGGetBoolAnswer)(CFStringRef capability);

static BOOL hasCapability(CFStringRef capability)
{
	if (!MGGetBoolAnswer) {
		void *libMobileGestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_LAZY);
		if (libMobileGestalt)
			MGGetBoolAnswer = dlsym(libMobileGestalt, "MGGetBoolAnswer");
	}
	if (MGGetBoolAnswer != NULL)
		return MGGetBoolAnswer(capability);
	return NO;
}

static BOOL hasSlomo()
{
	return hasCapability(CFSTR("RearFacingCameraHFRCapability"));
}

static BOOL hasPano()
{
	return hasCapability(CFSTR("PanoramaCameraCapability"));
}
