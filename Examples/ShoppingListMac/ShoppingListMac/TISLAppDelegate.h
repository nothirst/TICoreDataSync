//
//  TISLAppDelegate.h
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

@class TISLSynchronizationController;

@interface TISLAppDelegate : NSObject <NSApplicationDelegate> {
@private
    TISLSynchronizationController *_syncController;
}

@property (nonatomic, assign) IBOutlet TISLSynchronizationController *syncController;

@end
