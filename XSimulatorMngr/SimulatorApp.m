//
//  AppDelegate.h
//  XSimulatorMngr
//
//  Copyright © 2017 assln. All rights reserved.
//

#import "SimulatorApp.h"
#import "SimulatorDevice.h"
#import <Cocoa/Cocoa.h>


@implementation SimulatorApp

// MARK: - Main

- (instancetype)initWithBundleId:(NSString *)bundleId simulator:(SimulatorDevice *)simulator {
    self = [super init];
    if (self) {
        self.bundleId = bundleId;
        self.simulator = simulator;
    }
    return self;
}

- (void)updateFromLastLaunchMapInfo:(NSDictionary *)mapInfo {
    self.bundlePath = mapInfo[@"BundleContainer"];
    self.sandboxPath = mapInfo[@"Container"];
}

- (void)updateFromAppStateInfo:(NSDictionary *)stateInfo {
    NSDictionary *compatInfo = stateInfo[@"compatibilityInfo"];
    if (compatInfo != nil) {
        self.bundlePath = compatInfo[@"bundlePath"];
        self.sandboxPath = compatInfo[@"sandboxPath"];
    }
}

- (void)refine {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (self.bundlePath != nil) {
        if ([[self.bundlePath lastPathComponent] rangeOfString: @".app"].location == NSNotFound) {
            NSURL *bundleURL = [[NSURL alloc] initFileURLWithPath: self.bundlePath];
            NSURL *appURL;
            NSDirectoryEnumerationOptions options = NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsHiddenFiles;
            NSDirectoryEnumerator *directory = [fileManager enumeratorAtURL:bundleURL
                                                 includingPropertiesForKeys:nil
                                                                    options:options
                                                               errorHandler:nil];

            while ((appURL = [directory nextObject])) {
                NSString *appPath = [appURL path];
                if ([[appPath lastPathComponent] rangeOfString: @".app"].location != NSNotFound) {
                    self.bundlePath = appPath;
                    break;
                }
            }
        }
        
        NSURL *infoURL = [[NSURL alloc] initFileURLWithPath: self.bundlePath];
        infoURL = [infoURL URLByAppendingPathComponent: @"Info.plist"];

        if (infoURL != nil && [fileManager fileExistsAtPath: [infoURL path]]) {
            NSData *plistData = [NSData dataWithContentsOfURL: infoURL];
            
            if (plistData != nil) {
                NSDictionary *plistInfo = [NSPropertyListSerialization propertyListWithData:plistData
                                                                                    options:NSPropertyListImmutable
                                                                                     format:nil error: nil];
                if (plistInfo != nil) {
                    [self discoverAppInfoFromPList: plistInfo];
                }
            }
        }
    }
}

- (void)discoverAppInfoFromPList:(NSDictionary *)plistInfo {
    self.name = plistInfo[@"CFBundleDisplayName"];
    if (!self.name) {
        self.name = plistInfo[@"CFBundleName"];
    }
}

- (void)validatePaths {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:self.bundlePath]) {
        self.bundlePath = nil;
    }
    if (![fileManager fileExistsAtPath:self.sandboxPath]) {
        self.sandboxPath = nil;
    }
}

@end
