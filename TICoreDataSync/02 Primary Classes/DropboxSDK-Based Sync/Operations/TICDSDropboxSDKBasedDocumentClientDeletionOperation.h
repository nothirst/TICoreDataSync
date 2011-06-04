//
//  TICDSDropboxSDKBasedDocumentClientDeletionOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 04/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentClientDeletionOperation.h"
#import "DropboxSDK.h"
/**
 `TICDSDropboxSDKBasedDocumentClientDeletionOperation` is a "deletion of client's sync data from a document" operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */

@interface TICDSDropboxSDKBasedDocumentClientDeletionOperation : TICDSDocumentClientDeletionOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_restClient;
    
    NSString *_clientDevicesDirectoryPath;
    NSString *_thisDocumentDeletedClientsDirectoryPath;
    NSString *_thisDocumentSyncChangesDirectoryPath;
    NSString *_thisDocumentSyncCommandsDirectoryPath;
    NSString *_thisDocumentWholeStoreDirectoryPath;
}

/** @name Properties */

/** The DropboxSDK `DBSession` for use by this operation's `DBRestClient`. */
@property (retain) DBSession *dbSession;

/** The DropboxSDK `DBRestClient` for use by this operation for methods relating to the global application directory. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to the `ClientDevices` directory. */
@property (retain) NSString *clientDevicesDirectoryPath;

/** The path to the document's `DeletedClients` directory. */
@property (retain) NSString *thisDocumentDeletedClientsDirectoryPath;

/** The path to the document's `SyncChanges` directory. */
@property (retain) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path to the document's `SyncCommands` directory. */
@property (retain) NSString *thisDocumentSyncCommandsDirectoryPath;

/** The path to the document's `WholeStore` directory. */
@property (retain) NSString *thisDocumentWholeStoreDirectoryPath;

@end
