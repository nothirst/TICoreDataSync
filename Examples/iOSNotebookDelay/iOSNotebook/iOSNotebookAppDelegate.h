//
//  iOSNotebookAppDelegate.h
//  iOSNotebook
//
//  Created by Tim Isted on 13/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface iOSNotebookAppDelegate : NSObject <UIApplicationDelegate> {
    TICDSDocumentSyncManager *_documentSyncManager;
    BOOL _downloadStoreAfterRegistering;
    BOOL _syncAfterRegistering;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (retain) TICDSDocumentSyncManager *documentSyncManager;
@property (nonatomic, assign, getter = shouldDownloadStoreAfterRegistering) BOOL downloadStoreAfterRegistering;
@property (nonatomic, assign, getter = shouldSyncAfterRegistering) BOOL syncAfterRegistering;

- (IBAction)beginSynchronizing:(id)sender;

@end
