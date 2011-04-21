//
//  TICDSLocalDropboxApplicationSyncManager.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSLocalDropboxApplicationSyncManager.h"


@implementation TICDSLocalDropboxApplicationSyncManager

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_localDropboxLocation release], _localDropboxLocation = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize localDropboxLocation = _localDropboxLocation;

@end
