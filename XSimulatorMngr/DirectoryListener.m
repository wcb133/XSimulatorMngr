//
//  DirectoryListener.m
//  XSimulatorMngr
//
//  Copyright © 2017 assln. All rights reserved.
//


#import "DirectoryListener.h"


void directoryListenerCallback(
                ConstFSEventStreamRef streamRef,
                void *clientCallBackInfo,
                size_t numEvents,
                void *eventPaths,
                const FSEventStreamEventFlags eventFlags[],
                const FSEventStreamEventId eventIds[])
{
    if (numEvents > 0) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDirectoryListenerChangedNotification object:nil];
    }
}


@interface DirectoryListener()
@property (nonatomic, assign) FSEventStreamRef stream;
@end


@implementation DirectoryListener

#pragma mark - Main

- (instancetype)init {
    self = [super init];
    if (self) {
        self.paths = [NSMutableArray array];
        self.latency = 5.0;
    }
    return self;
}

- (void)start {
    CFArrayRef pathsToWatch = (__bridge CFArrayRef)self.paths;
    void *callbackInfo = NULL;
    
    _stream = FSEventStreamCreate(NULL,
                                 &directoryListenerCallback,
                                 callbackInfo,
                                 pathsToWatch,
                                 kFSEventStreamEventIdSinceNow,
                                 _latency,
                                 kFSEventStreamCreateFlagNone);

    FSEventStreamScheduleWithRunLoop(_stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(_stream);
}

- (void)stop {
    if (_stream) {
        FSEventStreamStop(_stream);
        FSEventStreamInvalidate(_stream); /* will remove from runloop */
        FSEventStreamRelease(_stream);
        _stream = NULL;
    }
}

@end
