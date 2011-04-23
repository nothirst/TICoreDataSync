//
//  MyDocument.h
//  ShoppingListMac
//
//  Created by Tim Isted on 14/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@class TIDocumentSyncChangesWindowController;

@interface MyDocument : NSPersistentDocument <TICDSDocumentSyncManagerDelegate> {
@private
    BOOL _syncEnabled;
    NSString *_documentSyncIdentifier;
    TICDSDocumentSyncManager *_documentSyncManager;
    TICDSSynchronizedManagedObjectContext *_synchronizedManagedObjectContext;
    NSTextField *_synchronizationStatusLabel;
    NSProgressIndicator *_synchronizingProgressIndicator;
    NSButton *_enableSynchronizationButton;
    NSUInteger _synchronizationActivity;
    TIDocumentSyncChangesWindowController *_documentSyncChangesWindowController;
}

//- (IBAction)initiateSynchronization:(id)sender;
- (IBAction)showSyncChangesWindow:(id)sender;
- (IBAction)configureSynchronization:(id)sender;
- (void)registerSyncManagerForDownloadedStoreWithIdentifier:(NSString *)anIdentifier;

@property (nonatomic, assign, getter=isSyncEnabled) BOOL syncEnabled;
@property (nonatomic, retain) NSString *documentSyncIdentifier;
@property (nonatomic, retain) TICDSDocumentSyncManager *documentSyncManager;
@property (nonatomic, retain) TICDSSynchronizedManagedObjectContext *synchronizedManagedObjectContext;
@property (nonatomic, assign) IBOutlet NSTextField *synchronizationStatusLabel;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *synchronizingProgressIndicator;
@property (nonatomic, assign) IBOutlet NSButton *enableSynchronizationButton;
@property (nonatomic, retain) TIDocumentSyncChangesWindowController *documentSyncChangesWindowController;
@end
