//
//  MyDocument.h
//  ShoppingListMac
//
//  Created by Tim Isted on 14/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@class TIDocumentSyncChangesWindowController;
@class TIDocumentShopsWindowController;

@interface MyDocument : NSPersistentDocument <TICDSDocumentSyncManagerDelegate> {
@private
    BOOL _syncEnabled;
    NSString *_documentSyncIdentifier;
    TICDSDocumentSyncManager *_documentSyncManager;
    TICDSSynchronizedManagedObjectContext *_synchronizedManagedObjectContext;
    NSTextField *_synchronizationStatusLabel;
    NSProgressIndicator *_synchronizingProgressIndicator;
    NSButton *_enableSynchronizationButton;
    NSButton *_synchronizeButton;
    NSButton *_vacuumButton;
    NSUInteger _synchronizationActivity;
    TIDocumentSyncChangesWindowController *_documentSyncChangesWindowController;
    TIDocumentShopsWindowController *_documentShopsWindowController;
}

- (IBAction)initiateSynchronization:(id)sender;
- (IBAction)initiateVacuum:(id)sender;
- (IBAction)showSyncChangesWindow:(id)sender;
- (IBAction)showShopsWindow:(id)sender;
- (IBAction)configureSynchronization:(id)sender;
- (IBAction)stressTestAddItemsAndShops:(id)sender;
- (void)configureSyncManagerForDownloadedStoreWithIdentifier:(NSString *)anIdentifier;

@property (nonatomic, assign, getter=isSyncEnabled) BOOL syncEnabled;
@property (nonatomic, retain) NSString *documentSyncIdentifier;
@property (nonatomic, retain) TICDSDocumentSyncManager *documentSyncManager;
@property (nonatomic, retain) TICDSSynchronizedManagedObjectContext *synchronizedManagedObjectContext;
@property (nonatomic, assign) IBOutlet NSTextField *synchronizationStatusLabel;
@property (nonatomic, assign) IBOutlet NSProgressIndicator *synchronizingProgressIndicator;
@property (nonatomic, assign) IBOutlet NSButton *enableSynchronizationButton;
@property (nonatomic, assign) IBOutlet NSButton *synchronizeButton;
@property (nonatomic, assign) IBOutlet NSButton *vacuumButton;
@property (nonatomic, retain) TIDocumentSyncChangesWindowController *documentSyncChangesWindowController;
@property (nonatomic, retain) TIDocumentShopsWindowController *documentShopsWindowController;
@end
