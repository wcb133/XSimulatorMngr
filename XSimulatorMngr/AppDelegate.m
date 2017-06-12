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
    self.recentAppsMenuItem.title = self.recent.appsDisabled ? @"Enable Recent App" : @"Disable Recent App";
    self.recentSimulatorMenuItem.title = self.recent.simulatorDisabled ? @"Enable Recent Simulator" : @"Disable Recent Simulator";
    
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

- (NSString *)simulatorDevicesDirectory {
    NSString *libraryPath = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    return [libraryPath stringByAppendingPathComponent: @"Developer/CoreSimulator/Devices/"];
}

- (NSDate *)modificationTimeFor:(NSString *)file {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[file stringByExpandingTildeInPath]
                                                                                error:nil];
    return [attributes fileModificationDate];
}


// MARK: - Actions

- (IBAction)actionRecentApps:(id)sender {
    self.recent.appsDisabled = !self.recent.appsDisabled;
    self.recentAppsMenuItem.title = self.recent.appsDisabled ? @"Enable Recent Apps" : @"Disable Recent Apps";
    [self.menuBuilder update];
}

- (IBAction)actionRecentSimulator:(id)sender {
    self.recent.simulatorDisabled = !self.recent.simulatorDisabled;
    self.recentSimulatorMenuItem.title = self.recent.simulatorDisabled ? @"Enable Recent Simulator" : @"Disable Recent Simulator";
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
