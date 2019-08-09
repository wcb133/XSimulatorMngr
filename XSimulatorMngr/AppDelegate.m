//
//  AppDelegate.m
//  XSimulatorMngr
//
//  Copyright © 2019 xndrs. All rights reserved.
//

#import "AppDelegate.h"
#import "RecentData.h"
#import "MenuBuilder.h"
#import "DirectoryListener.h"


@interface AppDelegate ()
@property (nonatomic, strong) NSDate *lastModificationDate;
@property (nonatomic, strong) RecentData *recentData;
@property (nonatomic, strong) MenuBuilder *menuBuilder;
@property (nonatomic, strong) DirectoryListener *dirListener;
@property (nonatomic, assign) BOOL needRefreshSimulators;

@property (weak) IBOutlet NSMenuItem *recentAppsMenuItem;
@property (weak) IBOutlet NSMenuItem *recentSimulatorMenuItem;
@property (weak) IBOutlet NSMenuItem *refreshSimulatorsMenuItem;
@property (weak) IBOutlet NSMenuItem *hideIPhoneMenuItem;
@property (weak) IBOutlet NSMenuItem *hideIPadMenuItem;
@property (weak) IBOutlet NSMenuItem *hideTVMenuItem;
@property (weak) IBOutlet NSMenuItem *hideWatchMenuItem;
@end


@implementation AppDelegate

// MARK: - Main

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.menu = self.statusMenu;
    self.statusItem.highlightMode = YES;

    NSImage *image = [NSImage imageNamed:@"statusIcon"];
    image.template = YES;
    [self.statusItem setImage:image];

    self.recentData = [[RecentData alloc] init];
    [self updateRecentAppMenuItem];
    [self updateRecentSimulatorMenuItem];
    [self updateHideIPhoneMenuItems];
    [self updateHideIPadMenuItems];
    [self updateHideTVMenuItems];
    [self updateHideWatchItems];
    
    self.statusMenu.autoenablesItems = NO;
    
    self.menuBuilder = [[MenuBuilder alloc] init];
    self.menuBuilder.menu = self.statusMenu;
    self.menuBuilder.recentData = self.recentData;

    self.needRefreshSimulators = YES;
    [self.statusMenu setDelegate:self];
    
    self.dirListener = [[DirectoryListener alloc] init];
    [self.dirListener.paths addObject:[self.recentData simulatorDevicesDirectory]];
    [self.dirListener start];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(directoryListenerChangedNotification:)
                                                 name:kDirectoryListenerChangedNotification
                                               object:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [self.dirListener stop];
}

// MARK: - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    if (self.needRefreshSimulators && !self.recentData.loading) {
        [self updateSimulatorsInfo];
    }
    [self.menuBuilder update];
}

// MARK: - DirectoryListener Notifications

- (void) directoryListenerChangedNotification:(NSNotification *) notification {
    self.needRefreshSimulators = YES;
}

// MARK: - Other

- (void)updateSimulatorsInfo {
    self.refreshSimulatorsMenuItem.enabled = NO;
    [self.recentData loadSimulatorsInfoWithCompletion:^{
        self.refreshSimulatorsMenuItem.enabled = YES;
        [self.menuBuilder update];
        self.needRefreshSimulators = NO;
    }];
}

- (void)updateRecentAppMenuItem {
    self.recentAppsMenuItem.title = self.recentData.appsDisabled ? @"Show Recent App" : @"Hide Recent App";
}

- (void)updateRecentSimulatorMenuItem {
    self.recentSimulatorMenuItem.title = self.recentData.simulatorDisabled ? @"Show Recent Simulator" : @"Hide Recent Simulator";
}

- (void)updateHideIPhoneMenuItems {
    self.hideIPhoneMenuItem.title = self.recentData.iphoneDisabled ? @"Show iPhone Simulators" : @"Hide iPhone Simulators";
}

- (void)updateHideIPadMenuItems {
    self.hideIPadMenuItem.title = self.recentData.ipadDisabled ? @"Show iPad Simulators" : @"Hide iPad Simulators";
}

- (void)updateHideTVMenuItems {
    self.hideTVMenuItem.title = self.recentData.tvDisabled ? @"Show TV Simulators" : @"Hide TV Simulators";
}

- (void)updateHideWatchItems {
    self.hideWatchMenuItem.title = self.recentData.watchDisabled ? @"Show Watch Simulators" : @"Hide Watch Simulators";
}

// MARK: - Actions

- (IBAction)actionEnableIPhoneSimulators:(id)sender {
    self.recentData.iphoneDisabled = !self.recentData.iphoneDisabled;
    [self updateHideIPhoneMenuItems];
    [self.menuBuilder update];
}

- (IBAction)actionEnableIPadSimulators:(id)sender {
    self.recentData.ipadDisabled = !self.recentData.ipadDisabled;
    [self updateHideIPadMenuItems];
    [self.menuBuilder update];
}

- (IBAction)actionEnableTVSimulators:(id)sender {
    self.recentData.tvDisabled = !self.recentData.tvDisabled;
    [self updateHideTVMenuItems];
    [self.menuBuilder update];
}

- (IBAction)actionEnableWatchSimulators:(id)sender {
    self.recentData.watchDisabled = !self.recentData.watchDisabled;
    [self updateHideWatchItems];
    [self.menuBuilder update];
}

- (IBAction)actionEnableRecentApps:(id)sender {
    self.recentData.appsDisabled = !self.recentData.appsDisabled;
    [self updateRecentAppMenuItem];
    [self.menuBuilder update];
}

- (IBAction)actionEnableRecentSimulators:(id)sender {
    self.recentData.simulatorDisabled = !self.recentData.simulatorDisabled;
    [self updateRecentSimulatorMenuItem];
    [self.menuBuilder update];
}

- (IBAction)actionRefreshSimulators:(id)sender {
    [self updateSimulatorsInfo];
}

- (IBAction)actionResetSimulators:(id)sender {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"XSimulatorMngr";
    notification.informativeText = @"Erase All Simulators...";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    
    self.menuBuilder.emulatorsErasing = YES;
    [self.menuBuilder update];
    [self.recentData.simulators removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *commandPath = [[NSBundle mainBundle] pathForResource:@"SimulatorErase" ofType:@"sh"];
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:commandPath];
        [task launch];
        [task waitUntilExit];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            notification.informativeText = @"All Simulators erased";
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            self.menuBuilder.emulatorsErasing = NO;
            [self updateSimulatorsInfo];
        });
    });
}

- (IBAction)actionQuit:(id)sender {
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    [NSApp terminate:NSApp];
}

@end
