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
@property (strong) NSString *clientDevicesDirectoryPath;

/** The path to the document's `DeletedClients` directory. */
@property (strong) NSString *thisDocumentDeletedClientsDirectoryPath;

/** The path to the document's `SyncChanges` directory. */
@property (strong) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path to the document's `SyncCommands` directory. */
@property (strong) NSString *thisDocumentSyncCommandsDirectoryPath;

/** The path to the document's `RecentSync` directory. */
@property (strong) NSString *thisDocumentRecentSyncsDirectoryPath;

/** The path to the document's `WholeStore` directory. */
@property (strong) NSString *thisDocumentWholeStoreDirectoryPath;

@end
