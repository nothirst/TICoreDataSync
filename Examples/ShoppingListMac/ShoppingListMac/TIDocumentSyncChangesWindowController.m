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

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aMoc
{
    self = [super initWithWindowNibName:@"DocumentSyncChangesWindow"];
    if( !self ) {
        return nil;
    }
    
    _managedObjectContext = aMoc;
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark -
#pragma mark Properties
@synthesize managedObjectContext = _managedObjectContext;

@end
