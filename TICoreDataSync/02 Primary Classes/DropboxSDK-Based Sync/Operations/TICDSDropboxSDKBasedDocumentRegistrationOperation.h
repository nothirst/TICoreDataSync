//
//  TICDSDropboxSDKBasedDocumentRegistrationOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"
#import <DropboxSDK/DropboxSDK.h>

/**
 `TICDSDropboxSDKBasedDocumentRegistrationOperation` is a document registration operation designed for use with a `TICDSDropboxSDKBasedApplicationSyncManager`.
 */

@interface TICDSDropboxSDKBasedDocumentRegistrationOperation : TICDSDocumentRegistrationOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_restClient;
    
    NSString *_documentsDirectoryPath;
    NSString *_clientDevicesDirectoryPath;
    NSString *_thisDocumentDirectoryPath;
    NSString *_thisDocumentDeletedClientsDirectoryPath;
    NSString *_deletedDocumentsDirectoryIdentifierPlistFilePath;
    NSString *_thisDocumentSyncChangesThisClientDirectoryPath;
    NSString *_thisDocumentSyncCommandsThisClientDirectoryPath;
    
    BOOL _completedThisDocumentSyncChangesThisClientDirectory;
    BOOL _errorCreatingThisDocumentSyncChangesThisClientDirectory;
    
    BOOL _completedThisDocumentSyncCommandsThisClientDirectory;
    BOOL _errorCreatingThisDocumentSyncCommandsThisClientDirectory;
    
    NSUInteger _numberOfDocumentDirectoriesToCreate;
    NSUInteger _numberOfDocumentDirectoriesThatWereCreated;
    NSUInteger _numberOfDocumentDirectoriesThatFailedToBeCreated;
}

/** @name Properties */

/** The DropboxSDK `DBSession` for use by this operation's `DBRestClient`. */
@property (strong) DBSession *dbSession;

/** The DropboxSDK `DBRestClient` for use by this operation. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to the `Documents` directory. */
@property (strong) NSString *documentsDirectoryPath;

/** The path to the `DeletedClients` directory. */
@property (strong) NSString *clientDevicesDirectoryPath;

/** The path to this document's directory inside the `Documents` directory. */
@property (strong) NSString *thisDocumentDirectoryPath;

/** The path to this document's `DeletedClients` directory. */
@property (strong) NSString *thisDocumentDeletedClientsDirectoryPath;

/** The path to this document's `identifier.plist` file inside the `DeletedDocuments` directory. */
@property (strong) NSString *deletedDocumentsDirectoryIdentifierPlistFilePath;

/** The path to this client's directory inside this document's `SyncChanges` directory. */
@property (strong) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

/** The path to this client's directory inside this document's `SyncCommands` directory. */
@property (strong) NSString *thisDocumentSyncCommandsThisClientDirectoryPath;

@end

#endif