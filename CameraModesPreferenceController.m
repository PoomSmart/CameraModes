#import "CameraModesPreferenceController.h"

@implementation CameraModesPreferenceController

- (NSArray *)specifiers
{
	if (_specifiers == nil) {
		NSMutableArray *specs = [NSMutableArray arrayWithArray:[[self loadSpecifiersFromPlistName:@"CameraModes" target:self] retain]];
		
		for (PSSpecifier *spec in specs) {
			NSString *Id = [spec identifier];
			if ([Id isEqualToString:@"timelapse"])
				self.timelapseSpec = spec;
			else if ([Id isEqualToString:@"slomo"])
				self.slomoSpec = spec;
			else if ([Id isEqualToString:@"video"])
				self.videoSpec = spec;
			else if ([Id isEqualToString:@"photo"])
				self.photoSpec = spec;
			else if ([Id isEqualToString:@"square"])
				self.squareSpec = spec;
			else if ([Id isEqualToString:@"pano"])
				self.panoSpec = spec;
		}
		
		if (!isiOS8Up)
			[specs removeObject:self.timelapseSpec];
		if (dlopen("/Library/MobileSubstrate/DynamicLibraries/SlalomEnabler.dylib", RTLD_LAZY) == NULL && !hasSlomo())
			[specs removeObject:self.slomoSpec];
		if (dlopen("/Library/MobileSubstrate/DynamicLibraries/PanoHook.dylib", RTLD_LAZY) == NULL && !hasPano())
			[specs removeObject:self.panoSpec];
		
		_specifiers = [specs copy];
	}
	return _specifiers;
}

@end
