//
//  TICDSSyncTransaction.h
//  TICoreDataSync-Mac
//
//  Created by Michael Fey on 4/9/13.
//  Copyright (c) 2013 No Thirst Software LLC. All rights reserved.
//

/** The `TICDSSyncTransaction` class exists to maintain data integrity with regards to applied sync changes.
 
 When the `TICoreDataSync` framework creates `TICDSSynchronizationOperation` instances to synchronize changes made to a document, these changes cannot be considered fully applied until the root `NSManagedObjectContext` of the application has been saved and the applied changes have been written to a persistent store.
 
 Prior to a synchronization process kicking off the `TICDSDocumentSyncManager` creates an instance of `TICDSSyncTransaction`. This instance is handed off to the `TICDSPreSynchronizationOperation`, `TICDSSynchronizationOperation`, and `TICDSPostSynchronizationOperation` instances. Just before the background context has been saved (the child context to the document's context) the `TICDSSyncTransaction` is "opened".
 
 Once the `TICDSSyncTransaction` instance is opened it begins listening to `NSManagedObjectContextDidSaveNotification` notifications for each of the application's `NSManagedObjectContext` instances starting with the document's context and traversing up the family tree to the root context. As these contexts are saved the `TICDSSyncTransaction` instance acknowledges that save until it gets a notification from the root context. Once the root context has been saved the `TICDSSyncTransaction` instance notifies its delegate that it can be closed.
 
 When the close method is called the `TICDSSyncTransaction` instance migrates the unsaved applied sync changes from its `*.unsavedticdsync` store to the `AppliedSyncChangeSets.ticdsync` store and notifies its delegate of success or failure.

 */
@interface TICDSSyncTransaction : NSObject

/** The URL to the unsaved applied sync change sets file for this sync transaction. */
@property (readonly) NSURL *unsavedAppliedSyncChangesFileURL;

/** The path to the applied sync change sets file. */
@property NSURL *appliedSyncChangesFileURL;

/** Any errors that occur while this transaction is open will be saved to this property. */
@property NSError *error;

/** The delegate that will receive `TICDSSyncTransactionDelegate` messages. */
@property (weak) id<TICDSSyncTransactionDelegate> delegate;

/** The current state of the sync transaction. Before the transaction has been opened its state will be TICDSSyncTransactionStateNotYetOpen. Once it has been opened its state will be TICDSSyncTransactionStateOpen. After the transaction has been closed successfully the state will be TICDSSyncTransactionStateClosed. If an attempt to close the transaction has been made and it fails the state will be TICDSSyncTransactionStateUnableToClose. The error property will most likely be non-nil as well. */
@property TICDSSyncTransactionState state;

#pragma mark Designated Initializer
/** @name Designated Initializer */

/** Initialize a sync transaction with the document's managed object context and the path to the directory where this transaction should write its unsaved applied sync change sets file.
 
 @param managedObjectContext The document's managed object context, the one that was registered with the document sync manager.
 @param unsavedAppliedSyncChangesDirectoryPath The path to the directory where the unsaved applied sync change set files will be placed. This directory location should exist before being given to the sync transaction.
 
 @return An initialized synchronization operation. */
- (id)initWithDocumentManagedObjectContext:(NSManagedObjectContext *)managedObjectContext unsavedAppliedSyncChangesDirectoryPath:(NSString *)unsavedAppliedSyncChangesDirectoryPath;

/**
 Immediately prior to a background sync `NSManagedObjectContext` being saved by a `TICDSSynchronizationOperation`, that operation's `TICDSSyncTransaction` should be "opened" by calling its open method.
 */
- (void)open;

/**
 Once the `TICDSSyncTransaction` indicates via its delegate that it can be closed this method can be called to close the transaction.
 */
- (void)close;

@end
