//
//  TICDSFileManagerBasedDocumentSyncManager.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentSyncManager.h"

/** The `TICDSFileManagerBasedDocumentSyncManager` describes a class used to synchronize documents with a remote service that can be accessed via an `NSFileManager`. This includes:
 
 1. Dropbox on the desktop (files are typically accessed via `~/Dropbox`)
 2. iDisk on the desktop
 
 No FileManagerBased-specific settings are required when you create a `TICDSFileManagerBasedDocumentSyncManager`--the `applicationDirectoryPath` is set automatically when you register (based on the properties set on the `TICDSFileManagerBasedApplicationSyncManager`).
 
 */
@interface TICDSFileManagerBasedDocumentSyncManager : TICDSDocumentSyncManager {
@private
    NSString *_applicationDirectoryPath;
    
    TIKQDirectoryWatcher *_directoryWatcher;
    NSMutableArray *_watchedClientDirectoryIdentifiers;
}

/** @name Properties */

/** A `TIKQDirectoryWatcher` used to watch for changes in the `SyncChanges` directories for this document. */
@property (nonatomic, readonly) TIKQDirectoryWatcher *directoryWatcher;

/** A mutable array containing the identifiers of clients currently being watched. */
@property (nonatomic, readonly) NSMutableArray *watchedClientDirectoryIdentifiers;

/** @name Paths */

/** The path to the root of the application. This will be set automatically when you register and supply a `TICDSFileManagerBasedApplicationSyncManager`. */
@property (nonatomic, copy) NSString *applicationDirectoryPath;

/** The path to the `ClientDevices` directory. */
@property (weak, nonatomic, readonly) NSString *clientDevicesDirectoryPath;

/** The path to this document's `identifier.plist` file inside the `DeletedDocuments` directory. */
@property (weak, nonatomic, readonly) NSString *deletedDocumentsThisDocumentIdentifierPlistPath;

/** The path to the `Documents` directory. */
@property (weak, nonatomic, readonly) NSString *documentsDirectoryPath;

/** The path to this document's directory inside the `Documents` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentDirectoryPath;

/** The path to this document's `DeletedClients` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentDeletedClientsDirectoryPath;

/** The path to this document's `SyncChanges` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path to this client's directory inside this document's `SyncChanges` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

/** The path to this document's `SyncCommands` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentSyncCommandsDirectoryPath;

/** The path to this client's directory inside this document's `SyncCommands` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentSyncCommandsThisClientDirectoryPath;

/** The path to this client's temporary `WholeStore` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryPath;

/** The path to this client's temporary `WholeStore.ticdsync` file. */
@property (weak, nonatomic, readonly) NSString *thisDocumentTemporaryWholeStoreFilePath;

/** The path to this client's temporary `AppliedSyncChangeSets.ticdsync` file. */
@property (weak, nonatomic, readonly) NSString *thisDocumentTemporaryAppliedSyncChangeSetsFilePath;

/** The path to this document's `WholeStore` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentWholeStoreDirectoryPath;

/** The path to this client's directory inside this document's `WholeStore` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentWholeStoreThisClientDirectoryPath;

/** The path to this client's `WholeStore.ticdsync` file. */
@property (weak, nonatomic, readonly) NSString *thisDocumentWholeStoreFilePath;

/** The path to this client's `AppliedSyncChangeSets.ticdsync` file. */
@property (weak, nonatomic, readonly) NSString *thisDocumentAppliedSyncChangeSetsFilePath;

/** The path to this document's `RecentSyncs` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentRecentSyncsDirectoryPath;

/** The path to this client's RecentSync file inside this document's `RecentSyncs` directory. */
@property (weak, nonatomic, readonly) NSString *thisDocumentRecentSyncsThisClientFilePath;

@end
