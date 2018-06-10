//
//  SimulatorDevice.m
//  XSimulatorMngr
//
//  Copyright © 2017 xndrs. All rights reserved.
//

#import "SimulatorDevice.h"
#import "SimulatorApp.h"

#define kSimulatorInfoFileName @"device.plist"

//
// Directories from https://github.com/somegeekintn/SimDirs
// ../data/Library/MobileInstallation/LastLaunchServicesMap.plist
// ../data/Library/BackBoard/applicationState.plist
// ../data/Library/Logs/MobileInstallation/mobile_installation.log.0
//
// Gather parsers from https://github.com/tue-savvy/SimulatorManager
//


@interface SimulatorDevice()
@property (nonatomic, strong) NSMutableArray *appList;
@property (nonatomic, strong) NSNumber *state;
@end


@implementation SimulatorDevice

// MARK:- Main

- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        if (![self loadFromPath:path]) {
            return nil;
        }
    }
    return self;
}

- (BOOL)loadFromPath:(NSString *)path {
    NSString *infoPlist = [path stringByAppendingPathComponent:kSimulatorInfoFileName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:infoPlist isDirectory:NULL]) {
        return NO;
    }

    NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile: infoPlist];
    if (infoDict) {
        self.name = infoDict[@"name"];
        [self updateRuntimeVersionFromValue: infoDict[@"runtime"]];
        self.title = [self.name stringByAppendingFormat:@" (%@)", self.runtimeVersion];
        
        self.udid = infoDict[@"UDID"];
        [self updateDeviceTypeFromValue: infoDict[@"deviceType"]];

        self.state = infoDict[@"state"];
        self.path = path;
        return YES;
    }
    return NO;
}

/// \returns path for device's application data container
- (NSString *)appDataPath {
    return  [self.path stringByAppendingPathComponent: @"data/Containers/Data/Application"];
}

/// Set OS version
///
/// \param value runtime version string
- (void) updateRuntimeVersionFromValue: (NSString *)value {
    NSString *version = [value stringByReplacingOccurrencesOfString: @"com.apple.CoreSimulator.SimRuntime." withString: @""];
    version = [version stringByReplacingOccurrencesOfString: @"iOS-" withString: @"iOS "];
    version = [version stringByReplacingOccurrencesOfString: @"-" withString: @"."];
    self.runtimeVersion = version;
}

/// Set device type from plist dictionary "deviceType" key
///
/// \param value diveceType string
- (void) updateDeviceTypeFromValue: (NSString *)value {
    NSArray *components = [value componentsSeparatedByString: @"."];
    self.deviceType = deviceTypeNone;
    if (components.count > 0) {
        NSString *lastComponent = [components[components.count - 1] lowercaseString];
        if ([lastComponent rangeOfString: @"iphone"].location != NSNotFound) {
            self.deviceType = deviceTypeIPhone;
        }
        else if ([lastComponent rangeOfString: @"ipad"].location != NSNotFound) {
            self.deviceType = deviceTypeIPad;
        }
        else if ([lastComponent rangeOfString: @"tv"].location != NSNotFound) {
            self.deviceType = deviceTypeTV;
        }
        else if ([lastComponent rangeOfString: @"watch"].location != NSNotFound) {
            self.deviceType = deviceTypeWatch;
        }
    }
}

- (NSArray *)applications {
    if (self.appList) {
        return self.appList;
    }

    self.appList = [NSMutableArray array];
    [self gatherAppInfoFromLastLaunchMap];
    [self gatherAppInfoFromAppState];
    [self gatherAppInfoFromInstallLogs];
    [self gatherAppInfoFromSystemLog];
    [self cleanupAppList];
    return self.appList;
}


// MARK:- Scan

- (void)gatherAppInfoFromLastLaunchMap {
    NSString *path = [self.path stringByAppendingPathComponent: @"data/Library/MobileInstallation/LastLaunchServicesMap.plist"];
    
    if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSDictionary *launchInfo = [NSDictionary dictionaryWithContentsOfFile:path];
        NSDictionary *userInfo = launchInfo[@"User"];
        
        for (NSString *bundleId in userInfo) {
            SimulatorApp *appInfo = [self appInfoWithBundleId: bundleId];
            if (appInfo != nil) {
                [appInfo updateFromLastLaunchMapInfo: userInfo[bundleId]];
            }
        }
    }
}

- (void)gatherAppInfoFromAppState {
    NSString *path = [self.path stringByAppendingPathComponent: @"data/Library/BackBoard/applicationState.plist"];

    if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSDictionary *stateInfo = [NSDictionary dictionaryWithContentsOfFile:path];

        for (NSString *bundleId in stateInfo) {
            if ([bundleId rangeOfString: @"com.apple"].location == NSNotFound) {
                SimulatorApp *appInfo = [self appInfoWithBundleId: bundleId];
                if (appInfo != nil) {
                    [appInfo updateFromAppStateInfo: stateInfo[bundleId]];
                }
            }
        }
    }
}

- (void)gatherAppInfoFromInstallLogs {
    NSString *path = [self.path stringByAppendingPathComponent: @"data/Library/Logs/MobileInstallation/mobile_installation.log.0"];
    
    if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *installLog = [[NSString alloc] initWithContentsOfFile:path usedEncoding: nil error: nil];

        if (installLog != nil) {
            for (NSString *line in [[installLog componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] reverseObjectEnumerator]) {
                if ([line rangeOfString: @"com.apple"].location == NSNotFound) {

                    NSRange	logHintRange = [line rangeOfString: @"makeContainerLiveReplacingContainer"];
                    if (logHintRange.location != NSNotFound) {
                        [self extractBundleLocationFromLogEntry: line];
                    }

                    logHintRange = [line rangeOfString: @"_refreshUUIDForContainer"];
                    if (logHintRange.location != NSNotFound) {
                        [self extractSandboxLocationFromLogEntry: line];
                    }
                }
            }
        }
    }
}

- (void)gatherAppInfoFromSystemLog {
    NSString *path = [self.path stringByAppendingPathComponent: @"data/Library/Logs/system.log"];
    
    if (path != nil && [[NSFileManager defaultManager] fileExistsAtPath:path]) {
        NSString *installLog = [[NSString alloc] initWithContentsOfFile:path usedEncoding: nil error: nil];
        
        if (installLog != nil) {
            for (NSString *line in [[installLog componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] reverseObjectEnumerator]) {
                if ([line rangeOfString: @"com.apple"].location == NSNotFound) {

                    NSRange	logHintRange = [line rangeOfString: @"makeContainerLiveReplacingContainer"];
                    if (logHintRange.location != NSNotFound) {
                        [self extractBundleLocationFromLogEntry: line];
                    }
                    
                    logHintRange = [line rangeOfString: @"_refreshUUIDForContainer"];
                    if (logHintRange.location != NSNotFound) {
                        [self extractSandboxLocationFromLogEntry: line];
                    }
                }
            }
        }
    }
}

- (void)extractBundleLocationFromLogEntry:(NSString *)inLine {
    NSArray	 *logComponents = [inLine componentsSeparatedByString: @" "];
    NSString *bundlePath = [logComponents lastObject];
    
    if (bundlePath != nil) {
        NSInteger bundleIdIndex = [logComponents count] - 3;

        if (bundleIdIndex >= 0) {
            NSString	 *bundleId = [logComponents objectAtIndex: bundleIdIndex];
            SimulatorApp *appInfo = [self appInfoWithBundleId:bundleId];

            if (appInfo != nil && !appInfo.bundlePath) {
                appInfo.bundlePath = bundlePath;
            }
        }
    }
}

- (void)extractSandboxLocationFromLogEntry:(NSString *)inLine {
    NSArray	 *logComponents = [inLine componentsSeparatedByString: @" "];
    NSString *sandboxPath = [logComponents lastObject];
    
    if (sandboxPath != nil) {
        NSInteger bundleIdIndex = [logComponents count] - 5;

        if (bundleIdIndex >= 0) {
            NSString	 *bundleId = [logComponents objectAtIndex:bundleIdIndex];
            SimulatorApp *appInfo = [self appInfoWithBundleId:bundleId];

            if (appInfo != nil && !appInfo.sandboxPath) {
                appInfo.sandboxPath = sandboxPath;
            }
        }
    }
}

- (SimulatorApp *)appInfoWithBundleId:(NSString *)bundleId {
    SimulatorApp *appInfo = nil;
    NSInteger appIndex;

    appIndex = [self.appList indexOfObjectPassingTest: ^(id inObject, NSUInteger inIndex, BOOL *outStop) {
        SimulatorApp *appInfo = inObject;
        *outStop = [appInfo.bundleId isEqualToString:bundleId];
        return *outStop;
    }];

    if (appIndex == NSNotFound) {
        appInfo = [[SimulatorApp alloc] initWithBundleId:bundleId simulator:self];
        [self.appList addObject: appInfo];
    }
    else {
        appInfo = [self.appList objectAtIndex: appIndex];
    }

    return appInfo;
}

- (void)cleanupAppList {
    NSMutableArray *mysteryApps = [NSMutableArray array];
    for (SimulatorApp *app in self.appList) {
        [app validatePaths];
        if ([app.bundlePath length] == 0) {
            [mysteryApps addObject:app];
        }
    }

    [self.appList removeObjectsInArray: mysteryApps];
    [self.appList sortUsingDescriptors: @[[NSSortDescriptor sortDescriptorWithKey: @"name" ascending:YES ]]];

    for (SimulatorApp *app in self.appList) {
        [app refine];
    }
}

@end
