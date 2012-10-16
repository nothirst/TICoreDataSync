//
//  TICDSFileManagerBasedDocumentClientDeletionOperation.h
//  Notebook
//
//  Created by Tim Isted on 04/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentClientDeletionOperation.h"

/**
 `TICDSFileManagerBasedDocumentClientDeletionOperation` is a "deletion of client's data from a document" operation designed for use with a `TICDSFileManagerBasedApplicationSyncManager`.
 */
@interface TICDSFileManagerBasedDocumentClientDeletionOperation : TICDSDocumentClientDeletionOperation {
@private
    NSString *_clientDevicesDirectoryPath;
    NSString *_thisDocumentDeletedClientsDirectoryPath;
    NSString *_thisDocumentSyncChangesDirectoryPath;
    NSString *_thisDocumentSyncCommandsDirectoryPath;
    NSString *_thisDocumentRecentSyncsDirectoryPath;
    NSString *_thisDocumentWholeStoreDirectoryPath;
}

/** @name Paths */

/** The path to the `ClientDevices` directory. */
@property (copy) NSString *clientDevicesDirectoryPath;

/** The path to the document's `DeletedClients` directory. */
@property (copy) NSString *thisDocumentDeletedClientsDirectoryPath;

/** The path to the document's `SyncChanges` directory. */
@property (copy) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path to the document's `SyncCommands` directory. */
@property (copy) NSString *thisDocumentSyncCommandsDirectoryPath;

/** The path to the document's `RecentSync` directory. */
@property (copy) NSString *thisDocumentRecentSyncsDirectoryPath;

/** The path to the document's `WholeStore` directory. */
@property (copy) NSString *thisDocumentWholeStoreDirectoryPath;

@end
