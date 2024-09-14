#import "Common.h"
#import <UIKit/UIKit.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <dlfcn.h>

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

static BOOL boolValueForKey(NSString *key, BOOL defaultValue){
    NSDictionary *pref = [NSDictionary dictionaryWithContentsOfFile:PREF_PATH];
    return pref[key] ? [pref[key] boolValue] : defaultValue;
}

@implementation CameraModesPreferenceController

- (NSMutableArray *)defaultCameraModes {
    NSMutableArray *array = [NSMutableArray array];
    [array addObject:@(cameraModeTimeLapse)];
    [array addObject:@(cameraModeSlalom)];
    [array addObject:@(cameraModeCinematic)];
    [array addObject:@(cameraModeVideo)];
    [array addObject:@(cameraModePhoto)];
    [array addObject:@(cameraModePortrait)];
    [array addObject:@(cameraModeSquare)];
    [array addObject:@(cameraModePano)];
    return array;
}

- (void)setSpecifier:(PSSpecifier *)specifier {
    [super setSpecifier:specifier];
    self.navigationItem.title = specifier.name;
    if ([self isViewLoaded]) {
        [(UITableView *)self.view setRowHeight:RowHeight];
        [(UITableView *)self.view reloadData];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 4;
}

- (NSString *)tableView:(UITableView *)table titleForHeaderInSection:(NSInteger)section {
    if (section == 1)
        return @"Enabled modes";
    if (section == 2)
        return @"Disabled modes";
    return nil;
}

- (BOOL)tableView:(UITableView *)view shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 3;
}

- (BOOL)tableView:(UITableView *)view shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == [self numberOfSectionsInTableView:tableView] - 1) {
        UIView *footer2 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 90)];
        footer2.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        footer2.backgroundColor = [UIColor clearColor];

        UILabel *lbl2 = [[UILabel alloc] initWithFrame:footer2.frame];
        lbl2.backgroundColor = [UIColor clearColor];
        lbl2.font = [UIFont systemFontOfSize:14.0f];
        lbl2.textColor = [UIColor grayColor];
        lbl2.text = @"© 2013 - 2024 PoomSmart";
        lbl2.textAlignment = NSTextAlignmentCenter;
        lbl2.lineBreakMode = NSLineBreakByWordWrapping;
        lbl2.numberOfLines = 2;
        lbl2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [footer2 addSubview:lbl2];
        return footer2;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return section == [self numberOfSectionsInTableView:tableView] - 1 ? 100 : 0;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1 || indexPath.section == 2;
}

- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
    if (section == 1)
        return _enabledModes.count;
    if (section == 2)
        return _disabledModes.count;
    return 1;
}

- (NSBundle *)cameraBundle {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        openCamera10();
        bundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/CameraUI.framework"];
    });
    return bundle;
}

- (NSString *)localizedStringForKey:(NSString *)key {
    NSString *table = [key isEqualToString:@"PORTRAIT"] ? @"CameraUI-bravo" : @"CameraUI";
    NSString *string = [self.cameraBundle localizedStringForKey:key value:@"" table:table];
    return [string capitalizedString];
}

- (NSString *)ModeStringFromCameraMode:(NSNumber *)number {
    int mode = number.intValue;
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
        case cameraModeTimeLapse:
            return [self localizedStringForKey:@"TIMELAPSE"];
        case cameraModePortrait:
            return [self localizedStringForKey:@"PORTRAIT"];
        case cameraModeCinematic:
            return [self localizedStringForKey:@"CINEMATIC"];
    }
    return nil;
}

- (void)toggleSwitch:(UISwitch *)sender {
    NSMutableDictionary *prefDict = [NSMutableDictionary dictionary];
    [prefDict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
    prefDict[@"tweakEnabled"] = @(sender.on);
    [prefDict.copy writeToFile:PREF_PATH atomically:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CMCELL";
    UITableViewCell *cell;
    NSUInteger section = indexPath.section;
    if (section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
        if (cell == nil) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"SwitchCell"];
#pragma GCC diagnostic pop
            cell.textLabel.text = @"Enable Tweak";
            UISwitch *toggle = [[UISwitch alloc] initWithFrame:CGRectZero];
            [toggle addTarget:self action:@selector(toggleSwitch:) forControlEvents:UIControlEventValueChanged];
            toggle.on = boolValueForKey(@"tweakEnabled", YES);
            cell.accessoryView = toggle;
        }
        return cell;
    } else if (section == 3) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ResetCell"];
        if (cell == nil) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
            cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"ResetCell"];
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
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier];
#pragma GCC diagnostic pop
        cell.textLabel.numberOfLines = 1;
        cell.textLabel.backgroundColor = [UIColor clearColor];
    }
    switch (section) {
        case 1:
            cell.textLabel.text = [self ModeStringFromCameraMode:_enabledModes[indexPath.row]];
            break;
        case 2:
            cell.textLabel.text = [self ModeStringFromCameraMode:_disabledModes[indexPath.row]];
    }
    return cell;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.allowsSelectionDuringEditing = YES;
    self.tableView.editing = YES;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"CameraModesCell"];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 3)
        [self resetCameraModes];
}

- (void)resetCameraModes {
    _enabledModes = [NSMutableOrderedSet orderedSetWithArray:[self defaultCameraModes]];
    _disabledModes = [NSMutableOrderedSet orderedSetWithArray:[NSArray array]];
    [self saveSettings];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.tableView reloadData];
}

- (void)saveSettings {
    NSMutableDictionary *prefDict = [NSMutableDictionary dictionary];
    [prefDict addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:PREF_PATH]];
    prefDict[kEnabledModesKey] = _enabledModes.array;
    prefDict[kDisabledModesKey] = _disabledModes.array;
    [prefDict.copy writeToFile:PREF_PATH atomically:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 1 || indexPath.section == 2;
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
    if (sourceIndexPath.section != proposedDestinationIndexPath.section) {
        BOOL outside = proposedDestinationIndexPath.section != 1 && proposedDestinationIndexPath.section != 2;
        BOOL onlyOne = _enabledModes.count == 1 && sourceIndexPath.section == 1;
        if (outside || onlyOne)
            return sourceIndexPath;
    }
    return proposedDestinationIndexPath;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    if (fromIndexPath.row == toIndexPath.row && fromIndexPath.section == toIndexPath.section)
        return;
    if (fromIndexPath.section == 1 && toIndexPath.section == 1) {
        NSObject *o = _enabledModes[fromIndexPath.row];
        [_enabledModes removeObjectAtIndex:fromIndexPath.row];
        [_enabledModes insertObject:o atIndex:toIndexPath.row];
    } else if (fromIndexPath.section == 2 && toIndexPath.section == 2) {
        NSObject *o = _disabledModes[fromIndexPath.row];
        [_disabledModes removeObjectAtIndex:fromIndexPath.row];
        [_disabledModes insertObject:o atIndex:toIndexPath.row];
    } else if (fromIndexPath.section == 1 && toIndexPath.section == 2) {
        NSObject *o = _enabledModes[fromIndexPath.row];
        [_enabledModes removeObjectAtIndex:fromIndexPath.row];
        [_disabledModes insertObject:o atIndex:toIndexPath.row];
    } else if (fromIndexPath.section == 2 && toIndexPath.section == 1) {
        NSObject *o = _disabledModes[fromIndexPath.row];
        [_disabledModes removeObjectAtIndex:fromIndexPath.row];
        [_enabledModes insertObject:o atIndex:toIndexPath.row];
    }
    [self saveSettings];
}

- (id)table {
    return nil;
}

- (UITableView *)tableView {
    return (UITableView *)self.view;
}

- (void)loadView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.delegate = self;
    tableView.rowHeight = RowHeight;
    self.view = tableView;
}

- (instancetype)init {
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
