//
//  DirectoryListener.h
//  XSimulatorMngr
//
//  Copyright © 2017 xndrs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDirectoryListenerChangedNotification @"kDirectoryListenerChangedNotification"

/*
 *  DirectoryListener
 *
 *  Discussion:
 *    The interface is used to receive events from OS about changes in directories
 */
@interface DirectoryListener : NSObject
@property (nonatomic, strong) NSMutableArray *paths;

/* 
 *  The number of seconds the service should wait after hearing about an event from the kernel
 *  before passing it along to the client via its callback.
 */
@property (nonatomic, assign) CFAbsoluteTime latency;

- (void)start;
- (void)stop;
@end
