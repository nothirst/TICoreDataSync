//
//  TICDSiCloudBasedDocumentRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentRegistrationOperation.h"

/**
 `TICDSiCloudBasedDocumentRegistrationOperation` is a document registration operation designed for use with a `TICDSiCloudBasedDocumentSyncManager`.
 */

@interface TICDSiCloudBasedDocumentRegistrationOperation : TICDSDocumentRegistrationOperation {
@private
    NSString *_documentsDirectoryPath;
    NSString *_clientDevicesDirectoryPath;
    NSString *_deletedDocumentsThisDocumentIdentifierPlistPath;
    NSString *_thisDocumentDeletedClientsDirectoryPath;
    NSString *_thisDocumentDirectoryPath;
    NSString *_thisDocumentSyncChangesThisClientDirectoryPath;
    NSString *_thisDocumentSyncCommandsThisClientDirectoryPath;
}

/** @name Paths */

/** The path to the `Documents` directory. */
@property (retain) NSString *documentsDirectoryPath;

/** The path to the `ClientDevices` directory. */
@property (retain) NSString *clientDevicesDirectoryPath;

/** The path to the document's `identifier.plist` file inside the `DeletedDocuments` directory. */
@property (retain) NSString *deletedDocumentsThisDocumentIdentifierPlistPath;

/** The path to this document's `DeletedClients` directory. */
@property (retain) NSString *thisDocumentDeletedClientsDirectoryPath;

/** The path to this document's directory inside the `Documents` directory. */
@property (retain) NSString *thisDocumentDirectoryPath;

/** The path to this client's directory inside this document's `SyncChanges` directory. */
@property (retain) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

/** The path to this client's directory inside this document's `SyncCommands` directory. */
@property (retain) NSString *thisDocumentSyncCommandsThisClientDirectoryPath;

@end
