//
//  SimulatorDeviceGroup.h
//  XSimulatorMngr
//
//  Copyright © 2018 xndrs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimulatorDevice.h"
#import "RunTimeVersionGroup.h"

@interface DeviceGroup : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) DeviceType deviceType;
@property (nonatomic, strong) NSMutableArray *runTimeVersionGroups;

- (instancetype)initWithTitle:(NSString *)title deviceType:(DeviceType)deviceType;
- (void)mapToRunTimeVersions:(SimulatorDevice *)device;
@end
