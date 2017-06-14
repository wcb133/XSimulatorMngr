//
//  SimulatorDevice.h
//  XSimulatorMngr
//
//  Copyright © 2017 assln. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum : NSUInteger {
    DeviceTypeNone,
    DeviceTypeIPhone,
    DeviceTypeIPad,
    DeviceTypeTV,
    DeviceTypeWatch
} DeviceType;


@interface SimulatorDevice : NSObject
@property (nonatomic, strong) NSString *udid;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *path;
@property (nonatomic, assign) DeviceType type;

- (instancetype)initWithPath:(NSString *)path;
- (NSArray *)applications;
- (NSString *)appDataPath;
@end
