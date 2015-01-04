#import "Common.h"
#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
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
- (UITableView *)tableView;
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

static BOOL boolValueForKey(NSString *key, BOOL defaultValue)
{
	NSDictionary *pref = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
	return pref[key] ? [pref[key] boolValue] : defaultValue;
}

#define RowHeight 44

@implementation CameraModesPreferenceController

- (NSMutableArray *)defaultCameraModes
{
	NSMutableArray *array = [NSMutableArray array];
	if (isiOS8Up)
		[array addObject:@6];
	if (dlopen("/Library/MobileSubstrate/DynamicLibraries/SlalomEnabler.dylib", RTLD_LAZY) || hasSlomo())
		[array addObject:@2];
	[array addObject:@1];
	[array addObject:@0];
	[array addObject:@4];
	if (dlopen("/Library/MobileSubstrate/DynamicLibraries/PanoHook.dylib", RTLD_LAZY) || hasPano())
		[array addObject:@3];
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
	return 3;
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
	return NO;
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
		lbl2.text = @"© 2013 - 2014 Thatchapon Unprasert\n(@PoomSmart)";
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

- (NSString *)ModeStringFromCameraMode:(NSNumber *)number
{
	NSInteger mode = number.intValue;
	switch (mode) {
		case 0:
			return @"Photo";
		case 1:
			return @"Video";
		case 2:
			return @"Slo-mo";
		case 3:
			return @"Panorama";
		case 4:
			return @"Square";
		case 6:
			return @"Time-Lapse";
	}
	return nil;
}

- (void)toggleSwitch:(UISwitch *)sender
{
	NSMutableDictionary *prefDict = [[NSDictionary dictionaryWithContentsOfFile:PREF_PATH] mutableCopy];
	if (prefDict == nil)
		prefDict = [NSMutableDictionary dictionary];
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
			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"SwitchCell"] autorelease];
			cell.textLabel.text = @"Enable Tweak";
			UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
			[toggle addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
			toggle.on = boolValueForKey(@"tweakEnabled", YES);
			cell.editingAccessoryView = toggle;
			[toggle release];
		}
		return cell;
	}
	cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
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
	[self.tableView setAllowsSelectionDuringEditing:YES];
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"CameraModesCell"];
	[self.tableView setEditing:YES];
}

- (void)saveSettings
{
	NSMutableDictionary *prefDict = [[NSDictionary dictionaryWithContentsOfFile:PREF_PATH] mutableCopy];
	if (prefDict == nil)
		prefDict = [NSMutableDictionary dictionary];
	prefDict[kEnabledModesKey] = _enabledModes.array;
	prefDict[kDisabledModesKey] = _disabledModes.array;
	[prefDict.copy writeToFile:PREF_PATH atomically:YES];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), PreferencesNotification, NULL, NULL, YES);
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
    else if (fromIndexPath.section == 2 && toIndexPath.section == 1) {
		NSObject *o = [_disabledModes[fromIndexPath.row] retain];
    	[_disabledModes removeObjectAtIndex:fromIndexPath.row];
    	[_disabledModes insertObject:o atIndex:toIndexPath.row];
    }
    else if (fromIndexPath.section == 1 && toIndexPath.section == 2) {
		NSObject *o = [_enabledModes[fromIndexPath.row] retain];
    	[_enabledModes removeObjectAtIndex:fromIndexPath.row];
    	[_disabledModes insertObject:o atIndex:toIndexPath.row];
    }
    else if (fromIndexPath.section == 1 && toIndexPath.section == 1) {
		NSObject *o = [_disabledModes[fromIndexPath.row] retain];
    	[_disabledModes removeObjectAtIndex:fromIndexPath.row];
    	[_enabledModes insertObject:o atIndex:toIndexPath.row];
    }
	[self saveSettings];
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

- (instancetype)init
{
	self = [super init];
	if (self) {
		NSDictionary *prefDict = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
		
		_enabledModes = prefDict[kEnabledModesKey] != nil ?
							[NSMutableOrderedSet orderedSetWithArray:prefDict[kEnabledModesKey]] :
							[NSMutableOrderedSet orderedSetWithArray:[self defaultCameraModes]];
		_disabledModes = prefDict[kDisabledModesKey] != nil ?
							[NSMutableOrderedSet orderedSetWithArray:prefDict[kDisabledModesKey]] :
							[NSMutableOrderedSet orderedSetWithArray:[NSArray array]];

		[self saveSettings];
		[[NSUserDefaults standardUserDefaults] synchronize];
		[self.tableView reloadData];
	}
	return self;
}

@end
