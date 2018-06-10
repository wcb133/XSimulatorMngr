//
//  AppDelegate.h
//  XSimulatorMngr
//
//  Copyright © 2017 xndrs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SimulatorDevice;

@interface SimulatorApp : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *bundleId;
@property (nonatomic, strong) NSString *bundlePath;
@property (nonatomic, strong) NSString *sandboxPath;
@property (nonatomic, weak)   SimulatorDevice *simulator;

- (instancetype)initWithBundleId:(NSString *)bundleId simulator:(SimulatorDevice *)simulator;
- (void)updateFromLastLaunchMapInfo:(NSDictionary *)mapInfo;
- (void)updateFromAppStateInfo:(NSDictionary *)stateInfo;
- (void)refine;
- (void)validatePaths;
@end
