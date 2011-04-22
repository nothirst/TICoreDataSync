//
//  TISLAppDelegate.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TISLAppDelegate.h"

#import "TISLSynchronizationController.h"

@implementation TISLAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    /*[[self syncController] performSelector:@selector(enableSynchronizationIfEnabledOrShowSyncConfigViewIfDisabled) withObject:nil afterDelay:5.0];*/
    [[self syncController] enableSynchronizationIfEnabledOrShowSyncConfigViewIfDisabled];
}

#pragma mark -
#pragma mark Properties
@synthesize syncController = _syncController;

@end
