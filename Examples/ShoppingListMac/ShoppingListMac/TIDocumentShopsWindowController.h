//
//  TIDocumentShopsWindowController.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


@interface TIDocumentShopsWindowController : NSWindowController {
@private
    NSManagedObjectContext *_managedObjectContext;
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)aContext;

@property (nonatomic, assign) NSManagedObjectContext *managedObjectContext;

@end
