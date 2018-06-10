//
//  RunTimeVersionGroup.m
//  XSimulatorMngr
//
//  Copyright © 2018 xndrs. All rights reserved.
//

#import "RunTimeVersionGroup.h"

@implementation RunTimeVersionGroup

// MARK:- Main

- (instancetype)initWithTitle:(NSString *)title {
    self = [super init];
    if (self) {
        self.title = title;
        self.devices = [NSMutableArray array];
    }
    return self;
}

@end
