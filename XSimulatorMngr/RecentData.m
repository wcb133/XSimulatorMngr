//
//  RecentData.m
//  XSimulatorMngr
//
//  Copyright © 2019 xndrs. All rights reserved.
//

#import "RecentData.h"

#define kRecentAppsDisabled      @"recentAppsDisabled"
#define kRecentSimulatorDisabled @"recentSimulatorDisabled"
#define kIPhoneDisabled          @"iphoneDisabled"
#define kIPadDisabled            @"ipadDisabled"
#define kWatchDisabled           @"watchDisabled"
#define kTvdDisabled             @"tvdDisabled"


@implementation RecentData

// MARK:- Main

-(instancetype)init {
    self = [super init];
    if (self) {
        self.deviceGroups = [NSMutableArray array];
        _appsDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kRecentAppsDisabled];
        _simulatorDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kRecentSimulatorDisabled];
        _iphoneDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kIPhoneDisabled];
        _ipadDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kIPadDisabled];
        _watchDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kWatchDisabled];
        _tvDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kTvdDisabled];
        _loading = NO;
    }
    return self;
}

// MARK: - Setters

- (void)setAppsDisabled:(BOOL)appsDisabled {
    _appsDisabled = appsDisabled;
    [[NSUserDefaults standardUserDefaults] setBool:_appsDisabled forKey:kRecentAppsDisabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSimulatorDisabled:(BOOL)simulatorDisabled {
    _simulatorDisabled = simulatorDisabled;
    [[NSUserDefaults standardUserDefaults] setBool:_simulatorDisabled forKey:kRecentSimulatorDisabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIphoneDisabled:(BOOL)iphoneDisabled {
    _iphoneDisabled = iphoneDisabled;
    [[NSUserDefaults standardUserDefaults] setBool:_iphoneDisabled forKey:kIPhoneDisabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setIpadDisabled:(BOOL)ipadDisabled {
    _ipadDisabled = ipadDisabled;
    [[NSUserDefaults standardUserDefaults] setBool:_ipadDisabled forKey:kIPadDisabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setWatchDisabled:(BOOL)watchDisabled {
    _watchDisabled = watchDisabled;
    [[NSUserDefaults standardUserDefaults] setBool:_watchDisabled forKey:kWatchDisabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setTvDisabled:(BOOL)tvDisabled {
    _tvDisabled = tvDisabled;
    [[NSUserDefaults standardUserDefaults] setBool:_tvDisabled forKey:kTvdDisabled];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

// MARK:- Other

- (NSString *)simulatorDevicesDirectory {
    NSString *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return [libraryPath stringByAppendingPathComponent: @"Developer/CoreSimulator/Devices/"];
}

- (void)loadSimulatorsInfoWithCompletion: (void(^)(void))completionHandler {
    self.loading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *devices = [self getDevicesInDirectory:[self simulatorDevicesDirectory]];
        NSMutableArray *groups = [self mapToGroups:devices];
        
        // sort groups
        for (DeviceGroup *group in groups) {
            [group.runTimeVersionGroups sortUsingComparator:^NSComparisonResult(id _Nonnull obj1, id _Nonnull obj2) {
                RunTimeVersionGroup *group1 = (RunTimeVersionGroup *)obj1;
                RunTimeVersionGroup *group2 = (RunTimeVersionGroup *)obj2;
                return [group1.title compare:group2.title options:(NSCaseInsensitiveSearch | NSNumericSearch)];
            }];
        }
        [groups sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
        
        // update UI
        self.deviceGroups = groups;
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.loading = NO;
            completionHandler();
        });
    });
}

/// \returns array of found simulator devices in directory
- (NSMutableArray *)getDevicesInDirectory:(NSString *)directory {
    NSMutableArray *devices = [NSMutableArray array];
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
    for (NSString *folderName in content) {
        SimulatorDevice *simulatorDevice = [[SimulatorDevice alloc] initWithPath:[directory stringByAppendingPathComponent:folderName]];
        if (simulatorDevice) {
            [devices addObject:simulatorDevice];
        }
    }
    return devices;
}

/// \returns map of devices. mappgin by deviceTitle->runTimeVersion
- (NSMutableArray *)mapToGroups:(NSArray *)devices {
    NSMutableArray *groups = [NSMutableArray array];
    for (SimulatorDevice *device in devices) {
        DeviceGroup *deviceGroup = nil;
        for (DeviceGroup *group in groups) {
            if ([group.title compare:device.name] == NSOrderedSame) {
                deviceGroup = group;
                break;
            }
        }
        if (deviceGroup == nil) {
            deviceGroup = [[DeviceGroup alloc] initWithTitle:device.name deviceType:device.deviceType];
            [groups addObject:deviceGroup];
        }
        [deviceGroup mapToRunTimeVersions:device];
    }
    return groups;
}

@end
