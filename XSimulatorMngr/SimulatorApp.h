//
//  AppDelegate.h
//  XSimulatorMngr
//
//  Copyright © 2019 xndrs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SimulatorDevice;

@interface SimulatorApp : NSObject
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSImage *appIcon;
@property (nonatomic, strong) NSString *bundleId;
@property (nonatomic, strong) NSString *bundlePath;
@property (nonatomic, strong) NSString *sandboxPath;
@property (nonatomic, weak)   SimulatorDevice *simulator;

- (instancetype)initWithBundlePath:(NSString *)bundlePath;
@end
