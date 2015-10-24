#import "Common.h"
#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Social/Social.h>
#import <dlfcn.h>

@interface PSViewController ()
@property (nonatomic, retain) PSSpecifier *specifier;
- (void)setView:(id)view;
@end

@interface CameraModesPreferenceController : PSViewController <UITableViewDataSource, UITableViewDelegate> {
	NSMutableOrderedSet *_enabledModes;
	NSMutableOrderedSet *_disabledModes;
}
@property (nonatomic, retain) PSSpecifier *timelapseSpec;
@property (nonatomic, retain) PSSpecifier *slomoSpec;
@property (nonatomic, retain) PSSpecifier *videoSpec;
@property (nonatomic, retain) PSSpecifier *photoSpec;
@property (nonatomic, retain) PSSpecifier *squareSpec;
@property (nonatomic, retain) PSSpecifier *panoSpec;
@property (nonatomic, retain) PSSpecifier *modeFiveSpec;
- (UITableView *)tableView;
@end

#define RowHeight 44.0f

extern BOOL MGGetBoolAnswer(CFStringRef);
static BOOL hasCapability(CFStringRef capability)
{
	return MGGetBoolAnswer(capability);
}

static BOOL hasSlomo()
{
	BOOL hasSlomoTweak;
	void *open = dlopen("/Library/MobileSubstrate/DynamicLibraries/SlalomEnabler.dylib", RTLD_LAZY);
	hasSlomoTweak = open != NULL;
	dlclose(open);
	return hasSlomoTweak || hasCapability(CFSTR("RearFacingCameraHFRCapability"));
}

static BOOL hasPano()
{
	BOOL hasPanoTweak;
	void *open = dlopen("/Library/MobileSubstrate/DynamicLibraries/PanoHook.dylib", RTLD_LAZY);
	hasPanoTweak = open != NULL;
	dlclose(open);
	return hasPanoTweak || hasCapability(CFSTR("PanoramaCameraCapability"));
}

static BOOL hasQRModeTweak()
{
	BOOL hasQRMode;
	void *open = dlopen("/Library/MobileSubstrate/DynamicLibraries/QRMode.dylib", RTLD_LAZY);
	hasQRMode = open != NULL;
	dlclose(open);
	return hasQRMode;
}

static BOOL boolValueForKey(NSString *key, BOOL defaultValue)
{
	NSDictionary *pref = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	return pref[key] ? [pref[key] boolValue] : defaultValue;
}

@implementation CameraModesPreferenceController

- (NSMutableArray *)defaultCameraModes
{
	NSMutableArray *array = [NSMutableArray array];
	if (isiOS8Up)
		[array addObject:@(cameraModeTimeLapse)];
	if (hasSlomo())
		[array addObject:@(cameraModeSlalom)];
	[array addObject:@(cameraModeVideo)];
	[array addObject:@(cameraModePhoto)];
	[array addObject:@(cameraModeSquare)];
	if (hasPano())
		[array addObject:@(cameraModePano)];
	if (hasQRModeTweak())
		[array addObject:@(cameraModeBW)];
	return array;
}

- (void)setSpecifier:(PSSpecifier *)specifier
{
	[super setSpecifier:specifier];
	self.navigationItem.title = [specifier name];
	if ([self isViewLoaded]) {
		[(UITableView *)self.view setRowHeight:RowHeight];
		[(UITableView *)self.view reloadData];
	}
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table
{
	return 4;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section
{
	if (section == 1)
		return @"Enabled modes";
	if (section == 2)
		return @"Disabled modes";
	return nil;
}

- (BOOL)tableView:(UITableView *)view shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath.section == 3;
}

- (BOOL)tableView:(UITableView *)view shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
	return NO;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
	if (section == [self numberOfSectionsInTableView:tableView] - 1) {
		UIView *footer2 = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 90)] autorelease];
		footer2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		footer2.backgroundColor = [UIColor clearColor];

		UILabel *lbl2 = [[UILabel alloc] initWithFrame:footer2.frame];
		lbl2.backgroundColor = [UIColor clearColor];
		lbl2.font = [UIFont systemFontOfSize:14.0f];
		lbl2.textColor = [UIColor grayColor];
		lbl2.text = @"© 2013 - 2015 Thatchapon Unprasert\n(@PoomSmart)";
		lbl2.textAlignment = NSTextAlignmentCenter;
		lbl2.lineBreakMode = NSLineBreakByWordWrapping;
		lbl2.numberOfLines = 2;
		lbl2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		[footer2 addSubview:lbl2];
		[lbl2 release];
    	return footer2;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section == [self numberOfSectionsInTableView:tableView] - 1 ? 100 : 0;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath.section == 1 || indexPath.section == 2;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section
{
	if (section == 1)
		return _enabledModes.count;
	if (section == 2)
		return _disabledModes.count;
	return 1;
}

- (NSString *)nameForModeFive
{
	if (hasQRModeTweak())
		return @"QR Mode";
	return @"Mode 5";
}

- (NSBundle *)cameraBundle
{
	static NSBundle *bundle = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		if (isiOS8Up)
			dlopen("/System/Library/PrivateFrameworks/CameraKit.framework/CameraKit", RTLD_LAZY);
		else
			dlopen("/System/Library/PrivateFrameworks/PhotoLibrary.framework/PhotoLibrary", RTLD_LAZY);
		bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/CameraKit.framework"];
		if (bundle == nil)
			bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/PhotoLibrary.framework"];
	});
	return bundle;
}

- (NSString *)localizedStringForKey:(NSString *)key
{
	NSString *table = isiOS8Up ? @"CameraKit" : ([key isEqualToString:@"SLALOM"] ? @"PhotoLibrary-Avalanche" : @"PhotoLibrary");
	NSString *string = [self.cameraBundle localizedStringForKey:key value:@"" table:table];
	return [string capitalizedString];
}

- (NSString *)ModeStringFromCameraMode:(NSNumber *)number
{
	NSInteger mode = number.integerValue;
	switch (mode) {
		case cameraModePhoto:
			return [self localizedStringForKey:@"PHOTO"];
		case cameraModeVideo:
			return [self localizedStringForKey:@"VIDEO"];
		case cameraModeSlalom:
			return [self localizedStringForKey:@"SLALOM"];
		case cameraModePano:
			return [self localizedStringForKey:@"PANO"];
		case cameraModeSquare:
			return [self localizedStringForKey:@"SQUARE"];
		case cameraModeBW:
			return [self nameForModeFive];
		case cameraModeTimeLapse:
			return [self localizedStringForKey:@"TIMELAPSE"];
	}
	return nil;
}

- (void)toggleSwitch:(UISwitch *)sender
{
	NSMutableDictionary *prefDict = [NSMutableDictionary dictionary];
	[prefDict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
	prefDict[@"tweakEnabled"] = @(sender.on);
	[prefDict.copy writeToFile:PREF_PATH atomically:YES];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), PreferencesNotification, NULL, NULL, YES);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"CMCELL";
	UITableViewCell *cell;
	NSUInteger section = indexPath.section;
	if (section == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
		if (cell == nil) {
			#pragma GCC diagnostic push
			#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"SwitchCell"] autorelease];
			#pragma GCC diagnostic pop
			cell.textLabel.text = @"Enable Tweak";
			UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
			[toggle addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
			toggle.on = boolValueForKey(@"tweakEnabled", YES);
			cell.accessoryView = toggle;
			[toggle release];
		}
		return cell;
	}
	else if (section == 3) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"ResetCell"];
		if (cell == nil) {
			#pragma GCC diagnostic push
			#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"ResetCell"] autorelease];
			#pragma GCC diagnostic pop
			cell.textLabel.text = @"Reset modes";
			cell.textLabel.textColor = [UIColor systemBlueColor];
			cell.textLabel.textAlignment = NSTextAlignmentCenter;
		}
		return cell;
	}
	cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		#pragma GCC diagnostic push
		#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
		#pragma GCC diagnostic pop
		cell.textLabel.numberOfLines = 1;
		cell.textLabel.backgroundColor = [UIColor clearColor];
		cell.textLabel.textColor = [UIColor blackColor];
	}
	switch (section) {
		case 1:
			cell.textLabel.text = [self ModeStringFromCameraMode:_enabledModes[indexPath.row]];
			break;
		case 2:
			cell.textLabel.text = [self ModeStringFromCameraMode:_disabledModes[indexPath.row]];
			break;
	}
	return cell;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.tableView.allowsSelectionDuringEditing = YES;
	self.tableView.editing = YES;
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"CameraModesCell"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	if (indexPath.section == 3)
		[self resetCameraModes];
}

- (void)resetCameraModes
{
	_enabledModes = [NSMutableOrderedSet orderedSetWithArray:[self defaultCameraModes]];
	_disabledModes = [NSMutableOrderedSet orderedSetWithArray:[NSArray array]];
	[self saveSettings];
	[[NSUserDefaults standardUserDefaults] synchronize];
	[self.tableView reloadData];
}

- (void)saveSettings
{
	#pragma GCC diagnostic push
	#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
	system("killall Camera");
	#pragma GCC diagnostic pop
	NSMutableDictionary *prefDict = [NSMutableDictionary dictionary];
	[prefDict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
	prefDict[kEnabledModesKey] = _enabledModes.array;
	prefDict[kDisabledModesKey] = _disabledModes.array;
	[prefDict.copy writeToFile:PREF_PATH atomically:YES];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), PreferencesNotification, NULL, NULL, YES);
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	return indexPath.section == 1 || indexPath.section == 2;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
	if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
		BOOL outside = proposedDestinationIndexPath.section != 1 && proposedDestinationIndexPath.section != 2;
		BOOL onlyOne = _enabledModes.count == 1 && sourceIndexPath.section == 1;
		if (outside || onlyOne)
			return sourceIndexPath;
	}
	return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
	if (fromIndexPath.row == toIndexPath.row && fromIndexPath.section == toIndexPath.section)
		return;
	if (fromIndexPath.section == 1 && toIndexPath.section == 1) {
		NSObject *o = [_enabledModes[fromIndexPath.row] retain];
    	[_enabledModes removeObjectAtIndex:fromIndexPath.row];
    	[_enabledModes insertObject:o atIndex:toIndexPath.row];
    }
    else if (fromIndexPath.section == 2 && toIndexPath.section == 2) {
		NSObject *o = [_disabledModes[fromIndexPath.row] retain];
    	[_disabledModes removeObjectAtIndex:fromIndexPath.row];
    	[_disabledModes insertObject:o atIndex:toIndexPath.row];
    }
    else if (fromIndexPath.section == 1 && toIndexPath.section == 2) {
		NSObject *o = [_enabledModes[fromIndexPath.row] retain];
    	[_enabledModes removeObjectAtIndex:fromIndexPath.row];
    	[_disabledModes insertObject:o atIndex:toIndexPath.row];
    }
    else if (fromIndexPath.section == 2 && toIndexPath.section == 1) {
		NSObject *o = [_disabledModes[fromIndexPath.row] retain];
    	[_disabledModes removeObjectAtIndex:fromIndexPath.row];
    	[_enabledModes insertObject:o atIndex:toIndexPath.row];
    }
	[self saveSettings];
}

- (id)table
{
	return nil;
}

- (UITableView *)tableView
{
    return (UITableView *)self.view;
}

- (void)loadView
{
	UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
	tableView.dataSource = self;
	tableView.delegate = self;
	tableView.rowHeight = RowHeight;
	self.view = tableView;
	[tableView release];
}

- (void)love
{
	SLComposeViewController *twitter = [[SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter] retain];
	[twitter setInitialText:@"#CameraModes by @PoomSmart is awesome!"];
	if (twitter != nil)
		[[self navigationController] presentViewController:twitter animated:YES completion:nil];
	[twitter release];
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		UIButton *heart = [[[UIButton alloc] initWithFrame:CGRectZero] autorelease];
		[heart setImage:[UIImage imageNamed:@"Heart" inBundle:[NSBundle bundleWithPath:@"/Library/PreferenceBundles/CameraModesSettings.bundle"]] forState:UIControlStateNormal];
		[heart sizeToFit];
		[heart addTarget:self action:@selector(love) forControlEvents:UIControlEventTouchUpInside];
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:heart] autorelease];
		NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
		_enabledModes = prefDict[kEnabledModesKey] != nil ?
							[NSMutableOrderedSet orderedSetWithArray:prefDict[kEnabledModesKey]] :
							[NSMutableOrderedSet orderedSetWithArray:[self defaultCameraModes]];
		_disabledModes = prefDict[kDisabledModesKey] != nil ?
							[NSMutableOrderedSet orderedSetWithArray:prefDict[kDisabledModesKey]] :
							[NSMutableOrderedSet orderedSetWithArray:[NSArray array]];

		if (hasQRModeTweak()) {
			// fix QRMode not appearing for users who updated from a previous version of CameraModes
			if (!([_enabledModes containsObject:@(cameraModeBW)] || [_disabledModes containsObject:@(cameraModeBW)]))
				[_enabledModes addObject:@(cameraModeBW)];
		} else {
			// remove it if qrmode was uninstalled
			[_enabledModes removeObject:@(cameraModeBW)];
			[_disabledModes removeObject:@(cameraModeBW)];
		}

		[self saveSettings];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[self.tableView reloadData];
	}
	return self;
}

@end
