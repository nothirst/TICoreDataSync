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
    NSArrayController *_arrayController;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aMoc;

@property (nonatomic, assign) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) IBOutlet NSArrayController *arrayController;

@end
