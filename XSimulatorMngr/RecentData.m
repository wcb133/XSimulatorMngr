//
//  RecentData.m
//  XSimulatorMngr
//
//  Copyright © 2017 assln. All rights reserved.
//

#import "RecentData.h"

#define kRecentAppsDisabled @"recentAppsDisabled"
#define kRecentSimulatorDisabled @"recentSimulatorDisabled"
#define kIPhoneDisabled @"iphoneDisabled"
#define kIPadDisabled @"ipadDisabled"
#define kWatchDisabled @"watchDisabled"
#define kTvdDisabled @"tvdDisabled"


@implementation RecentData

// MARK:- Main

-(instancetype)init {
    self = [super init];
    if (self) {
        _appsDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kRecentAppsDisabled];
        _simulatorDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kRecentSimulatorDisabled];
        _iphoneDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kIPhoneDisabled];
        _ipadDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kIPadDisabled];
        _watchDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kWatchDisabled];
        _tvDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:kTvdDisabled];
        _loading = YES;
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


// MARK: - Other

- (NSString *)simulatorDevicesDirectory {
    NSString *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return [libraryPath stringByAppendingPathComponent:@"Developer/CoreSimulator/Devices/"];
}

- (void)loadSimulatorsWithCompletion:(void(^)(void))completionHandler {
    self.loading = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *simulators = [NSMutableArray array];
        NSString *directory = [self simulatorDevicesDirectory];
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
        
        for (NSString *folderName in content) {
            SimulatorDevice *simulator = [[SimulatorDevice alloc] initWithPath:[directory stringByAppendingPathComponent:folderName]];
            if (simulator) {
                [simulators addObject:simulator];
            }
        }
        
        [simulators sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
        self.simulators = simulators;
        dispatch_sync(dispatch_get_main_queue(), ^{
            self.loading = NO;
            completionHandler();
        });
    });
}

@end
