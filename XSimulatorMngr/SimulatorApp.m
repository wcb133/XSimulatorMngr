//
//  AppDelegate.h
//  XSimulatorMngr
//
//  Copyright © 2019 xndrs. All rights reserved.
//

#import "SimulatorApp.h"


@implementation SimulatorApp

// MARK: - Main

- (instancetype)initWithBundlePath:(NSString *)bundlePath {
    self = [super init];
    if (self) {
        self.bundlePath = bundlePath;
    }
    return self;
}

@end
