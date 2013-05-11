//
//  NotebookAppDelegate.h
//  Notebook
//
//  Created by Tim Isted on 04/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TICoreDataSync.h"

@interface NotebookAppDelegate : NSObject <NSApplicationDelegate, NSTokenFieldDelegate, TICDSApplicationSyncManagerDelegate, TICDSDocumentSyncManagerDelegate> {
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
@property (nonatomic, assign) IBOutlet NSProgressIndicator *activityIndicator;
@property (nonatomic, assign) BOOL existingStore;

@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

@property (retain) TICDSDocumentSyncManager *documentSyncManager;
@property (nonatomic, assign, getter = shouldDownloadStoreAfterRegistering) BOOL downloadStoreAfterRegistering;
@property (nonatomic, assign) NSInteger activity;

- (IBAction)saveAction:sender;
- (IBAction)beginSynchronizing:(id)sender;

@end
