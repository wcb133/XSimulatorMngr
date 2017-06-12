//
//  SimulatorDevice.h
//  XSimulatorMngr
//
//  Copyright © 2017 assln. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SimulatorDevice : NSObject
@property (nonatomic, strong) NSString *udid;
@property (nonatomic, strong) NSString *deviceType;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *runtime;
@property (nonatomic, strong) NSNumber *state;
@property (nonatomic, strong) NSString *path;

- (instancetype)initWithPath:(NSString *)path;
- (NSArray *)applications;
- (NSString *)appDataPath;
- (NSString *)runtimeVersion;
@end
