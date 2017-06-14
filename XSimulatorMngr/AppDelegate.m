//
//  AppDelegate.m
//  XSimulatorMngr
//
//  Copyright © 2017 assln. All rights reserved.
//

#import "AppDelegate.h"
#import "RecentData.h"
#import "MenuBuilder.h"


@interface AppDelegate ()
@property (nonatomic, strong) NSDate *lastModificationDate;
@property (nonatomic, strong) RecentData *recent;
@property (nonatomic, strong) MenuBuilder *menuBuilder;
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
    
    self.menuBuilder = [[MenuBuilder alloc] init];
    self.menuBuilder.menu = self.statusMenu;
    self.menuBuilder.recent = self.recent;

    [self loadSimulators];
    [self.statusMenu setDelegate:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
}


// MARK: - NSMenuDelegate

- (void)menuNeedsUpdate:(NSMenu *)menu {
    [self.menuBuilder update];
}


// MARK: - Other

- (void)loadSimulators {
    self.refreshSimulatorsMenuItem.enabled = NO;
    [self.recent loadSimulatorsWithCompletion:^{
        self.refreshSimulatorsMenuItem.enabled = YES;
        [self.menuBuilder update];
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
}

- (IBAction)actionQuit:(id)sender {
    [[NSStatusBar systemStatusBar] removeStatusItem:self.statusItem];
    [NSApp terminate:NSApp];
}

@end
