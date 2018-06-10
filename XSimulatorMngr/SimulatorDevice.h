//
//  SimulatorDevice.h
//  XSimulatorMngr
//
//  Copyright © 2017 xndrs. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    deviceTypeNone,
    deviceTypeIPhone,
    deviceTypeIPad,
    deviceTypeTV,
    deviceTypeWatch
} DeviceType;


@interface SimulatorDevice : NSObject
@property (nonatomic, strong) NSString *udid;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *runtimeVersion;
@property (nonatomic, assign) DeviceType deviceType;

- (instancetype)initWithPath:(NSString *)path;
- (NSArray *)applications;
- (NSString *)appDataPath;
@end
