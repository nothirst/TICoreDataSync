//
//  TIDocumentShopsWindowController.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TIDocumentShopsWindowController.h"


@implementation TIDocumentShopsWindowController

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext
{
    self = [super initWithWindowNibName:@"DocumentShopsWindow"];
    if( !self ) {
        return nil;
    }
    
    _managedObjectContext = aContext;
    
    return self;
}

#pragma mark -
#pragma mark Properties
@synthesize managedObjectContext = _managedObjectContext;

@end
