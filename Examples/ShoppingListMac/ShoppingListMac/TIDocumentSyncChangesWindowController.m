//
//  TIDocumentSyncChangesWindowController.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TIDocumentSyncChangesWindowController.h"
#import "TICoreDataSync.h"


@implementation TIDocumentSyncChangesWindowController

#pragma mark -
#pragma mark Notifications
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    NSLog(@"%@", [[[self arrayController] selectedObjects] lastObject]);
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    self = [super initWithWindowNibName:@"DocumentSyncChangesWindow"];
    if( !self ) {
        return nil;
    }
    
    _managedObjectContext = aMoc;
    
    return self;
}

#pragma mark -
#pragma mark Properties
@synthesize managedObjectContext = _managedObjectContext;
@synthesize arrayController = _arrayController;

@end
