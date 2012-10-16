//
//  TICDSFileManagerBasedDocumentRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentRegistrationOperation.h"

/**
 `TICDSFileManagerBasedDocumentRegistrationOperation` is a document registration operation designed for use with a `TICDSFileManagerBasedDocumentSyncManager`.
 */

@interface TICDSFileManagerBasedDocumentRegistrationOperation : TICDSDocumentRegistrationOperation {
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
@property (copy) NSString *documentsDirectoryPath;

/** The path to the `ClientDevices` directory. */
@property (copy) NSString *clientDevicesDirectoryPath;

/** The path to the document's `identifier.plist` file inside the `DeletedDocuments` directory. */
@property (copy) NSString *deletedDocumentsThisDocumentIdentifierPlistPath;

/** The path to this document's `DeletedClients` directory. */
@property (copy) NSString *thisDocumentDeletedClientsDirectoryPath;

/** The path to this document's directory inside the `Documents` directory. */
@property (copy) NSString *thisDocumentDirectoryPath;

/** The path to this client's directory inside this document's `SyncChanges` directory. */
@property (copy) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

/** The path to this client's directory inside this document's `SyncCommands` directory. */
@property (copy) NSString *thisDocumentSyncCommandsThisClientDirectoryPath;

@end
