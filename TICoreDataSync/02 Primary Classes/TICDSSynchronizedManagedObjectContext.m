//
//  TICDSSynchronizedManagedObjectContext.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSSynchronizedManagedObjectContext.h"


@implementation TICDSSynchronizedManagedObjectContext

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_documentSyncManager release], _documentSyncManager = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize documentSyncManager = _documentSyncManager;

@end
