//
//  NotebookAppDelegate.h
//  Notebook
//
//  Created by Tim Isted on 04/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NotebookAppDelegate : NSObject <NSApplicationDelegate, NSTokenFieldDelegate> {
@private
    NSWindow *_window;
    NSArrayController *_notesArrayController;
    BOOL _existingStore;
    
    NSPersistentStoreCoordinator *__persistentStoreCoordinator;
    NSManagedObjectModel *__managedObjectModel;
    NSManagedObjectContext *__managedObjectContext;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSArrayController *notesArrayController;
@property (nonatomic, assign) BOOL existingStore;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:sender;

@end
