//
//  TIDocumentSyncChangesWindowController.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

@interface TIDocumentSyncChangesWindowController : NSWindowController {
@private
    NSManagedObjectContext *_managedObjectContext;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aMoc;

@property (nonatomic, assign) NSManagedObjectContext *managedObjectContext;

@end
