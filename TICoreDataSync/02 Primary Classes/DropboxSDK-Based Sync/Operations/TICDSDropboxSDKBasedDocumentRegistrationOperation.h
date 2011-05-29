//
//  TICDSDropboxSDKBasedDocumentRegistrationOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"
#import "DropboxSDK.h"

/**
 `TICDSDropboxSDKBasedDocumentRegistrationOperation` is a document registration operation designed for use with a `TICDSDropboxSDKBasedApplicationSyncManager`.
 */

@interface TICDSDropboxSDKBasedDocumentRegistrationOperation : TICDSDocumentRegistrationOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_restClient;
    
    NSString *_documentsDirectoryPath;
    NSString *_thisDocumentDirectoryPath;
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
@property (retain) DBSession *dbSession;

/** The DropboxSDK `DBRestClient` for use by this operation for methods relating to the global application directory. */
@property (nonatomic, retain) DBRestClient *restClient;

/** @name Paths */

/** The path to the `Documents` directory. */
@property (retain) NSString *documentsDirectoryPath;

/** The path to this document's directory inside the `Documents` directory. */
@property (retain) NSString *thisDocumentDirectoryPath;

/** The path to this document's `identifier.plist` file inside the `DeletedDocuments` directory. */
@property (retain) NSString *deletedDocumentsDirectoryIdentifierPlistFilePath;

/** The path to this client's directory inside this document's `SyncChanges` directory. */
@property (retain) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

/** The path to this client's directory inside this document's `SyncCommands` directory. */
@property (retain) NSString *thisDocumentSyncCommandsThisClientDirectoryPath;

@end

#endif