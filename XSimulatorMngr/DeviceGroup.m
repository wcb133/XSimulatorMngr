//
//  DeviceGroup.m
//  XSimulatorMngr
//
//  Copyright © 2019 xndrs. All rights reserved.
//

#import "DeviceGroup.h"

@implementation DeviceGroup

// MARK: - Main

- (instancetype)initWithTitle:(NSString *)title deviceType:(DeviceType)deviceType {
    self = [super init];
    if (self) {
        self.title = title;
        self.deviceType = deviceType;
        self.runTimeVersionGroups = [NSMutableArray array];
    }
    return self;
}

// MARK: - Map device

- (void)mapToRunTimeVersions:(SimulatorDevice *)device {
    RunTimeVersionGroup *runTimeVersionGroup = nil;
    for (RunTimeVersionGroup *group in self.runTimeVersionGroups) {
        if ([group.title compare:device.runtimeVersion] == NSOrderedSame) {
            runTimeVersionGroup = group;
            break;
        }
    }
    if (runTimeVersionGroup == nil) {
        runTimeVersionGroup = [[RunTimeVersionGroup alloc] initWithTitle:device.runtimeVersion];
        [self.runTimeVersionGroups addObject:runTimeVersionGroup];
    }
    [runTimeVersionGroup.devices addObject:device];
}

@end
