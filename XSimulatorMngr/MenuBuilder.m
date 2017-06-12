//
//  MenuBuilder.m
//  XSimulatorMngr
//
//  Copyright © 2017 assln. All rights reserved.
//

#import "MenuBuilder.h"

@implementation MenuBuilder


// MARK: - Main

- (void)update {
    NSUInteger count = [[self.menu itemArray] count];
    for (NSInteger index = 0; index < count - 7; index++) {
        [self.menu removeItemAtIndex:0];
    }
    
    if (self.recent.loading) {
        [self buildLoadingMenu];
    }
    else {
        [self buildMenuForSimulators];
        
        if (!self.recent.simulatorDisabled) {
            [self buildMenuForRecentSimulator];
        }
        
        if (!self.recent.appsDisabled) {
            [self buildMenuForRecentApps];
        }
        
        self.recent.updated = YES;
    }
}

- (void)buildLoadingMenu {
    NSInteger menuIndex = 0;
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.enabled = NO;
    menuItem.title = @"Loading...";
    [self.menu insertItem:menuItem atIndex:menuIndex++];
    [self.menu insertItem:[NSMenuItem separatorItem] atIndex:menuIndex++];
}

- (void)buildMenuForSimulators {
    NSInteger index = 0;
    for (SimulatorDevice *simulator in self.recent.simulators) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = simulator;
        menuItem.title = [simulator.name stringByAppendingFormat: @" (%@)", simulator.runtimeVersion];
        menuItem.target = self;
        menuItem.action = @selector(noAction:);
        
        NSMenu *subMenu = [[NSMenu alloc] init];
        menuItem.submenu = subMenu;
        [self buildMenu:subMenu forSimulator:simulator];
        [self.menu insertItem:menuItem atIndex:index];
        index++;
    }
    [self.menu insertItem:[NSMenuItem separatorItem] atIndex:index];
}

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

- (void)buildMenuForRecentApps {
    NSInteger menuIndex = 0;
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.enabled = NO;
    menuItem.title = @"Recent App";
    [self.menu insertItem:menuItem atIndex:menuIndex++];
    
    if (self.recent.app) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = self.recent.app;
        menuItem.title = self.recent.app.name? : @"<Unknown>";
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

- (void)buildMenuForRecentSimulator {
    NSInteger menuIndex = 0;
    NSMenuItem *menuItem = [[NSMenuItem alloc] init];
    menuItem.enabled = NO;
    menuItem.title = @"Recent Simulator";
    [self.menu insertItem:menuItem atIndex:menuIndex++];
    
    if (self.recent.simulator) {
        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        menuItem.representedObject = self.recent.simulator;
        menuItem.title = [self.recent.simulator.name stringByAppendingFormat:@" (%@)", self.recent.simulator.runtimeVersion];
        menuItem.target = self;
        menuItem.action = @selector(noAction:);
        
        NSMenu *subMenu = [[NSMenu alloc] init];
        menuItem.submenu = subMenu;
        [self buildMenu:subMenu forSimulator:self.recent.simulator];
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


// MARK: - Action

-(void)noAction:(id)sender{
}

- (void)actionOpenSimulatorApp:(NSMenuItem *)menuItem {
    self.recent.app = menuItem.representedObject;
    self.recent.simulator = self.recent.app.simulator;
    self.recent.updated = YES;
    
    NSString *appDataPath = self.recent.app.sandboxPath;
    if (appDataPath) {
        [[NSWorkspace sharedWorkspace] openURL: [NSURL fileURLWithPath: appDataPath]];
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"XSimulator Manager";
        [alert addButtonWithTitle: @"Close"];
        alert.informativeText = [NSString stringWithFormat: @"Cannot find data folder for the app '%@'", self.recent.app.name];
        [alert runModal];
    }
}

- (void)actionOpenSimulatorFolder:(NSMenuItem *)menuItem {
    self.recent.simulator = menuItem.representedObject;
    self.recent.updated = YES;
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:self.recent.simulator.path]];
}

- (void)actionOpenSimulatorDataFolder:(NSMenuItem *)menuItem {
    self.recent.simulator = menuItem.representedObject;
    self.recent.updated = YES;
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[self.recent.simulator appDataPath]]];
}

@end
