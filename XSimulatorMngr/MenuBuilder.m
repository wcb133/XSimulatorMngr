//
//  MenuBuilder.m
//  XSimulatorMngr
//
//  Copyright © 2017 xndrs. All rights reserved.
//

#import "MenuBuilder.h"

@implementation MenuBuilder

// MARK:- Main

- (void)update {
    NSUInteger count = [[self.menu itemArray] count];
    for (NSInteger index = 0; index < count - 12; index++) {
        [self.menu removeItemAtIndex:0];
    }
    
    NSArray<NSMenuItem *> *array = self.menu.itemArray;
    for (NSInteger index = 0; index < 11 && index < array.count; index++) {
        NSMenuItem *item = array[index];
        item.enabled = !self.emulatorsErasing;
    }
    
    if (self.emulatorsErasing) {
        [self buildErasingMenu];
    }
    else {
        if (self.recentData.loading) {
            [self buildLoadingMenu];
        }
        else {
            [self buildMenuForSimulators];
            
            if (!self.recentData.simulatorDisabled) {
                [self buildMenuForRecentSimulator];
            }
            
            if (!self.recentData.appsDisabled) {
                [self buildMenuForRecentApps];
            }
            
            self.recentData.updated = YES;
        }
    }
}


// MARK:- Build menu

- (void)buildErasingMenu {
    NSInteger menuIndex = 0;
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.enabled = NO;
    menuItem.title = @"Erasing ...";
    [self.menu insertItem:menuItem atIndex:menuIndex++];
    [self.menu insertItem:[NSMenuItem separatorItem] atIndex:menuIndex++];
}

- (void)buildLoadingMenu {
    NSInteger menuIndex = 0;
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.enabled = NO;
    menuItem.title = @"Loading...";
    [self.menu insertItem:menuItem atIndex:menuIndex++];
    [self.menu insertItem:[NSMenuItem separatorItem] atIndex:menuIndex++];
}

/// Build main menu, based on device groups
- (void)buildMenuForSimulators {
    NSInteger index = 0;
    for (DeviceGroup *group in self.recentData.deviceGroups) {
        if (self.recentData.iphoneDisabled && group.deviceType == deviceTypeIPhone) {
            continue;
        }
        if (self.recentData.ipadDisabled && group.deviceType == deviceTypeIPad) {
            continue;
        }
        if (self.recentData.tvDisabled && group.deviceType == deviceTypeTV) {
            continue;
        }
        if (self.recentData.watchDisabled && group.deviceType == deviceTypeWatch) {
            continue;
        }

        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = group;
        menuItem.title = group.title? : @"<Unknown>";
        menuItem.target = self;
        menuItem.action = @selector(noAction:);

        NSMenu *subMenu = [[NSMenu alloc] init];
        menuItem.submenu = subMenu;
        [self buildMenu:subMenu forGroup:group];
        [self.menu insertItem:menuItem atIndex:index];
        index++;
    }
    [self.menu insertItem:[NSMenuItem separatorItem] atIndex:index];
}

/// Build menu based on runTimeVersion, per each device group
- (void)buildMenu:(NSMenu *)subMenu forGroup:(DeviceGroup *)group {
    for (RunTimeVersionGroup *runTimeVersionGroup in group.runTimeVersionGroups) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = runTimeVersionGroup;
        menuItem.title = runTimeVersionGroup.title? : @"<Unknown>";
        menuItem.target = self;
        menuItem.action = @selector(noAction:);
        
        for (SimulatorDevice *simulator in runTimeVersionGroup.devices) {
            NSMenu *subMenu = [[NSMenu alloc] init];
            menuItem.submenu = subMenu;
            [self buildMenu:subMenu forSimulator:simulator];
        }
        [subMenu addItem:menuItem];
    }
}

/// Build simulator menu
- (void)buildMenu:(NSMenu *)subMenu forSimulator:(SimulatorDevice *)simulator {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.representedObject = simulator;
    menuItem.title = @"Simulator Folder";
    menuItem.target = self;
    menuItem.action = @selector(actionOpenSimulatorFolder:);
    NSString *rootPath = simulator.path;
    if (![fileManager fileExistsAtPath:rootPath]) {
        menuItem.image  = [NSImage imageNamed: @"warning"];
    }
    [subMenu addItem:menuItem];
    
    NSString *dataPath = [simulator appDataPath];
    if ([fileManager fileExistsAtPath:dataPath]) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.title = @"App Data Folder";
        menuItem.representedObject = simulator;
        menuItem.target = self;
        menuItem.action = @selector(actionOpenSimulatorDataFolder:);
        [subMenu addItem:menuItem];
    }
    [subMenu addItem:[NSMenuItem separatorItem]];
    
    for (SimulatorApp *app in simulator.applications) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = app;
        menuItem.title = app.name? : @"<Unknown>";
        menuItem.target = self;
        menuItem.action = @selector(actionOpenSimulatorApp:);
        NSString *dataPath = [app sandboxPath];
        if (![fileManager fileExistsAtPath:dataPath]) {
            menuItem.image  = [NSImage imageNamed: @"warning"];
        }
        [subMenu addItem:menuItem];
    }
    
    if (simulator.applications.count == 0) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.enabled = NO;
        menuItem.title = @"No App";
        [subMenu addItem:menuItem];
    }
}

/// Build menu to show recent apps
- (void)buildMenuForRecentApps {
    NSInteger menuIndex = 0;
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.enabled = NO;
    menuItem.title = @"Recent App";
    [self.menu insertItem:menuItem atIndex:menuIndex++];
    
    if (self.recentData.app) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = self.recentData.app;
        menuItem.title = self.recentData.app.name? : @"<Unknown>";
        menuItem.target = self;
        menuItem.action = @selector(actionOpenSimulatorApp:);
        [self.menu insertItem:menuItem atIndex:menuIndex++];
    }
    else {
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.enabled = NO;
        menuItem.title = @"No Recent";
        [self.menu insertItem:menuItem atIndex:menuIndex++];
    }
    
    [self.menu insertItem:[NSMenuItem separatorItem] atIndex:menuIndex++];
}

/// Build menu to show recent simulators
- (void)buildMenuForRecentSimulator {
    NSInteger menuIndex = 0;
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.enabled = NO;
    menuItem.title = @"Recent Simulator";
    [self.menu insertItem:menuItem atIndex:menuIndex++];
    
    if (self.recentData.simulator) {
        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = self.recentData.simulator;
        menuItem.title = self.recentData.simulator.title;
        menuItem.target = self;
        menuItem.action = @selector(noAction:);
        
        NSMenu *subMenu = [[NSMenu alloc] init];
        menuItem.submenu = subMenu;
        [self buildMenu:subMenu forSimulator:self.recentData.simulator];
        [self.menu insertItem:menuItem atIndex:menuIndex++];
    }
    else {
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.enabled = NO;
        menuItem.title = @"No Recent";
        [self.menu insertItem:menuItem atIndex:menuIndex++];
    }
    
    [self.menu insertItem:[NSMenuItem separatorItem] atIndex:menuIndex++];
}


// MARK:- Action

-(void)noAction:(id)sender{
}

- (void)actionOpenSimulatorApp:(NSMenuItem *)menuItem {
    self.recentData.app = menuItem.representedObject;
    self.recentData.simulator = self.recentData.app.simulator;
    self.recentData.updated = YES;
    
    NSString *appDataPath = self.recentData.app.sandboxPath;
    if (appDataPath) {
        [[NSWorkspace sharedWorkspace] openURL: [NSURL fileURLWithPath: appDataPath]];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"XSimulator Manager";
        [alert addButtonWithTitle: @"Close"];
        alert.informativeText = [NSString stringWithFormat: @"Cannot find data folder for the app '%@'", self.recentData.app.name];
        [alert runModal];
    }
}

- (void)actionOpenSimulatorFolder:(NSMenuItem *)menuItem {
    self.recentData.simulator = menuItem.representedObject;
    self.recentData.updated = YES;
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:self.recentData.simulator.path]];
}

- (void)actionOpenSimulatorDataFolder:(NSMenuItem *)menuItem {
    self.recentData.simulator = menuItem.representedObject;
    self.recentData.updated = YES;
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[self.recentData.simulator appDataPath]]];
}

@end
