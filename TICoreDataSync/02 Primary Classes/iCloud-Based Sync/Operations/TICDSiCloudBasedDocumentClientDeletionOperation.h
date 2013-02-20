//
//  TICDSiCloudBasedDocumentClientDeletionOperation.h
//  Notebook
//
//  Created by Tim Isted on 04/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentClientDeletionOperation.h"

/**
 `TICDSiCloudBasedDocumentClientDeletionOperation` is a "deletion of client's data from a document" operation designed for use with a `TICDSiCloudBasedApplicationSyncManager`.
 */
@interface TICDSiCloudBasedDocumentClientDeletionOperation : TICDSDocumentClientDeletionOperation {
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
@property (retain) NSString *clientDevicesDirectoryPath;

/** The path to the document's `DeletedClients` directory. */
@property (retain) NSString *thisDocumentDeletedClientsDirectoryPath;

/** The path to the document's `SyncChanges` directory. */
@property (retain) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path to the document's `SyncCommands` directory. */
@property (retain) NSString *thisDocumentSyncCommandsDirectoryPath;

/** The path to the document's `RecentSync` directory. */
@property (retain) NSString *thisDocumentRecentSyncsDirectoryPath;

/** The path to the document's `WholeStore` directory. */
@property (retain) NSString *thisDocumentWholeStoreDirectoryPath;

@end
