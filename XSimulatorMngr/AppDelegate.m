//
//  AppDelegate.m
//  XSimulatorMngr
//
//  Copyright © 2017 assln. All rights reserved.
//

#import "AppDelegate.h"
#import "RecentData.h"
#import "MenuBuilder.h"
#import "DirectoryListener.h"


@interface AppDelegate ()
@property (nonatomic, strong) NSDate *lastModificationDate;
@property (nonatomic, strong) RecentData *recent;
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

    self.recent = [[RecentData alloc] init];
    [self updateRecentAppMenuItem];
    [self updateRecentSimulatorMenuItem];
    [self updateHideIPhoneMenuItems];
    [self updateHideIPadMenuItems];
    [self updateHideTVMenuItems];
    [self updateHideWatchItems];
    
    self.statusMenu.autoenablesItems = NO;
    
    self.menuBuilder = [[MenuBuilder alloc] init];
    self.menuBuilder.menu = self.statusMenu;
    self.menuBuilder.recent = self.recent;


    self.needRefreshSimulators = YES;
    [self.statusMenu setDelegate:self];
    

    self.dirListener = [[DirectoryListener alloc] init];
    [self.dirListener.paths addObject:[self.recent simulatorDevicesDirectory]];
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
    if (self.needRefreshSimulators && !self.recent.loading) {
        [self loadSimulators];
    }
    [self.menuBuilder update];
}


// MARK: - DirectoryListener Notifications

- (void) directoryListenerChangedNotification:(NSNotification *) notification {
    NSLog (@"directory changed");
    self.needRefreshSimulators = YES;
}


// MARK: - Other

- (void)loadSimulators {
    self.refreshSimulatorsMenuItem.enabled = NO;
    [self.recent loadSimulatorsWithCompletion:^{
        self.refreshSimulatorsMenuItem.enabled = YES;
        [self.menuBuilder update];
        self.needRefreshSimulators = NO;
    }];
}

- (void)updateRecentAppMenuItem {
    self.recentAppsMenuItem.title = self.recent.appsDisabled ? @"Show Recent App" : @"Hide Recent App";
}

- (void)updateRecentSimulatorMenuItem {
    self.recentSimulatorMenuItem.title = self.recent.simulatorDisabled ? @"Show Recent Simulator" : @"Hide Recent Simulator";
}

- (void)updateHideIPhoneMenuItems {
    self.hideIPhoneMenuItem.title = self.recent.iphoneDisabled ? @"Show iPhone Simulators" : @"Hide iPhone Simulators";
}

- (void)updateHideIPadMenuItems {
    self.hideIPadMenuItem.title = self.recent.ipadDisabled ? @"Show iPad Simulators" : @"Hide iPad Simulators";
}

- (void)updateHideTVMenuItems {
    self.hideTVMenuItem.title = self.recent.tvDisabled ? @"Show TV Simulators" : @"Hide TV Simulators";
}

- (void)updateHideWatchItems {
    self.hideWatchMenuItem.title = self.recent.watchDisabled ? @"Show Watch Simulators" : @"Hide Watch Simulators";
}



// MARK: - Actions

- (IBAction)actionEnableIPhoneSimulators:(id)sender {
    self.recent.iphoneDisabled = !self.recent.iphoneDisabled;
    [self updateHideIPhoneMenuItems];
    [self.menuBuilder update];
}

- (IBAction)actionEnableIPadSimulators:(id)sender {
    self.recent.ipadDisabled = !self.recent.ipadDisabled;
    [self updateHideIPadMenuItems];
    [self.menuBuilder update];
}

- (IBAction)actionEnableTVSimulators:(id)sender {
    self.recent.tvDisabled = !self.recent.tvDisabled;
    [self updateHideTVMenuItems];
    [self.menuBuilder update];
}

- (IBAction)actionEnableWatchSimulators:(id)sender {
    self.recent.watchDisabled = !self.recent.watchDisabled;
    [self updateHideWatchItems];
    [self.menuBuilder update];
}

- (IBAction)actionEnableRecentApps:(id)sender {
    self.recent.appsDisabled = !self.recent.appsDisabled;
    [self updateRecentAppMenuItem];
    [self.menuBuilder update];
}

- (IBAction)actionEnableRecentSimulators:(id)sender {
    self.recent.simulatorDisabled = !self.recent.simulatorDisabled;
    [self updateRecentSimulatorMenuItem];
    [self.menuBuilder update];
}

- (IBAction)actionRefreshSimulators:(id)sender {
    [self loadSimulators];
}

- (IBAction)actionResetSimulators:(id)sender {
    NSUserNotification *notification = [[NSUserNotification alloc] init];
    notification.title = @"XSimulatorMngr";
    notification.informativeText = @"Erase All Simulators...";
    [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
    
    self.menuBuilder.emulatorsErasing = YES;
    [self.menuBuilder update];
    [self.recent.simulators removeAllObjects];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *commandPath = [[NSBundle mainBundle] pathForResource:@"SimulatorErase" ofType:@"sh"];
        
        NSTask *task = [[NSTask alloc] init];
        [task setLaunchPath:commandPath];
        [task launch];
        [task waitUntilExit];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            notification.informativeText = @"All Simulators are erased";
            [[NSUserNotificationCenter defaultUserNotificationCenter] deliverNotification:notification];
            self.menuBuilder.emulatorsErasing = NO;
            [self loadSimulators];
        });
    });
}

- (IBAction)actionQuit:(id)sender {
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    [NSApp terminate:NSApp];
}

@end
