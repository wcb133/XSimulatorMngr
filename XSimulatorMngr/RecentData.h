//
//  RecentData.h
//  XSimulatorMngr
//
//  Copyright © 2017 xndrs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SimulatorApp.h"
#import "SimulatorDevice.h"
#import "DeviceGroup.h"


@interface RecentData: NSObject
@property (nonatomic, assign) BOOL appsDisabled;
@property (nonatomic, assign) BOOL simulatorDisabled;
@property (nonatomic, assign) BOOL iphoneDisabled;
@property (nonatomic, assign) BOOL ipadDisabled;
@property (nonatomic, assign) BOOL watchDisabled;
@property (nonatomic, assign) BOOL tvDisabled;

@property (nonatomic, assign) BOOL updated;
@property (nonatomic, assign) BOOL loading;
@property (nonatomic, strong) NSMutableArray *simulators;
@property (nonatomic, strong) NSMutableArray *deviceGroups;
@property (nonatomic, weak)   SimulatorDevice *simulator;
@property (nonatomic, weak)   SimulatorApp *app;

- (void) loadSimulatorsWithCompletion: (void(^)(void))completionHandler;
- (NSString *) simulatorDevicesDirectory;
@end
