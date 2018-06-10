//
//  RunTimeVersionGroup.h
//  XSimulatorMngr
//
//  Copyright © 2018 xndrs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RunTimeVersionGroup : NSObject
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSMutableArray *devices;

- (instancetype)initWithTitle:(NSString *)title;
@end
