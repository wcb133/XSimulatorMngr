//
//  SimulatorDevice.m
//  XSimulatorMngr
//
//  Copyright © 2019 xndrs. All rights reserved.
//

#import "SimulatorDevice.h"
#import "SimulatorApp.h"
#import "SQLiteReader.h"

#define kSimulatorInfoFile @"device.plist"
#define kTempPlistPath @"/tmp/xsimulatormngr_appinfo.plist"

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
    NSString *infoPlist = [path stringByAppendingPathComponent:kSimulatorInfoFile];
    BOOL isDir = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:infoPlist isDirectory:&isDir] || isDir) {
        return NO;
    }

    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: infoPlist];
    if (dict) {
        self.name = dict[@"name"];
        [self updateRuntimeVersionFromValue: dict[@"runtime"]];
        self.title = [self.name stringByAppendingFormat:@" (%@)", self.runtimeVersion];
        
        self.udid = dict[@"UDID"];
        [self updateDeviceTypeFromValue: dict[@"deviceType"]];

        self.state = dict[@"state"];
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
    [self scanForBundleApplicationFolder];
    [self scanForApplicationInfo];
    [self scanForDataApplicationFolder];
    return self.appList;
}

// MARK:- Scan

- (void)scanForBundleApplicationFolder {
    NSString *appsFolder = [self.path stringByAppendingPathComponent:@"data/Containers/Bundle/Application"];
    BOOL isDir = NO;
    if (![[NSFileManager defaultManager] fileExistsAtPath:appsFolder isDirectory:&isDir] && !isDir) {
        return;
    }
    
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:appsFolder error:nil];
    for (NSString *folderName in content) {
        NSString *bundlePath = [appsFolder stringByAppendingPathComponent:folderName];
        if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePath isDirectory:&isDir] && isDir) {
            [self.appList addObject:[[SimulatorApp alloc] initWithBundlePath:bundlePath]];
        }
    }
}

- (void)scanForApplicationInfo {
    for (SimulatorApp *app in self.appList) {
        NSArray *folderContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:app.bundlePath error:nil];
        for (NSString *folderItem in folderContent) {
            
            NSRange range = [folderItem rangeOfString: @".app" options:NSBackwardsSearch];
            if (!(range.location != NSNotFound && folderItem.length - 4 == range.location && range.location > 0)) {
                continue;
            }
            
            // set initial name
            app.name = [folderItem substringWithRange:NSMakeRange(0, range.location)];
            
            // get application info from plist
            NSString *plistPath = [[app.bundlePath stringByAppendingPathComponent:folderItem] stringByAppendingPathComponent:@"Info.plist"];
            if ([[NSFileManager defaultManager] fileExistsAtPath: plistPath]) {
                NSData *plistData = [NSData dataWithContentsOfFile:plistPath];
                if (plistData != nil) {
                    NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:plistData
                                                                                        options:NSPropertyListImmutable
                                                                                         format:nil error: nil];
                    if (plist != nil) {
                        [self scanForApplicationInfoFromPList:plist app:app];
                    }
                }
            }
        }
    }
}

- (void)scanForApplicationInfoFromPList:(NSDictionary *)plist app:(SimulatorApp *)app {
    // set app name from plist
    NSString *name = plist[@"CFBundleDisplayName"];
    if ([name length] == 0) {
        name = plist[@"CFBundleName"];
    }
    if ([name length] > 0) {
        app.name = name;
    }
    
    // set app bundle identifier
    app.bundleId = plist[@"CFBundleIdentifier"];
}

- (void)scanForDataApplicationFolder {
    if ([self.appList count] == 0) {
        return;
    }
    
    NSString *databasePath = [self.path stringByAppendingPathComponent:@"/data/Library/FrontBoard/applicationState.db"];
    if (![[NSFileManager defaultManager] fileExistsAtPath: databasePath]) {
        return;
    }
    
    SQLiteReader *reader = [[SQLiteReader alloc] init];
    if ([reader open:databasePath]) {
        
        for (SimulatorApp *app in self.appList) {
            NSInteger identifier = [reader getIdForApplicationIdentifier:app.bundleId];
            if (identifier <= 0) {
                continue;
            }
            
            NSInteger keyIdentifier = [reader getIdForKey:@"compatibilityInfo"];
            if (keyIdentifier <= 0) {
                continue;
            }
            
            NSData *data = [reader getValueFor:identifier withKey:keyIdentifier];
            if (data == NULL) {
                continue;
            }
            
            NSError *error;
            NSPropertyListFormat format;
            id plist = [NSPropertyListSerialization propertyListWithData: data
                                                                 options: NSPropertyListImmutable
                                                                  format: &format
                                                                   error: &error];
            if (plist == nil || format != NSPropertyListBinaryFormat_v1_0) {
                NSLog (@"[ERROR]: could not deserialize binary data");
                continue;
            }
            
            [plist writeToFile:kTempPlistPath atomically:NO];
            NSDictionary *dict= [NSDictionary dictionaryWithContentsOfFile:kTempPlistPath];
            if (dict == NULL) {
                continue;
            }
            
            id objects = dict[@"$objects"];
            if (objects && [objects isKindOfClass:[NSArray class]]) {
                for (id object in objects) {
                    if ([object isKindOfClass:[NSString class]]) {
                        if ([((NSString *)object) rangeOfString:@"/data/Containers/Data/Application/"].location != NSNotFound) {
                            app.sandboxPath = (NSString *)object;
                            break;
                        }
                    }
                }
            }
        }
    }
    [reader close];
}

@end
