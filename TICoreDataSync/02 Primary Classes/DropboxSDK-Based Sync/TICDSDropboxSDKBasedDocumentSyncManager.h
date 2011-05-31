//
//  TICDSDropboxSDKBasedDocumentSyncManager.h
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICDSDocumentSyncManager.h"

/** The `TICDSDropboxSDKBasedDocumentSyncManager` describes a class used to synchronize an iOS document with a remote service that can be accessed via the Dropbox SDK.
 
 The requirements are the same as for the `TICDSDropboxSDKBasedApplicationSyncManager`. 
 
 Note that if you wish to use a `DBSession` object other than the default session, you will need to specify this on each document sync manager you create before calling any other methods.
 */

@class DBSession;

@interface TICDSDropboxSDKBasedDocumentSyncManager : TICDSDocumentSyncManager {
@private
    DBSession *_dbSession;
    
    NSString *_applicationDirectoryPath;
}

/** @name Properties */

/** The DropboxSDK `DBSession` object to use for Dropbox access. If you don't set this property, TICoreDataSync will use the `[DBSession sharedSession]`. */
@property (nonatomic, retain) DBSession *dbSession;

/** @name Paths */

/** The path to the root of the application. This will be set automatically when you register and supply a `TICDSFileManagerBasedApplicationSyncManager`. */
@property (nonatomic, retain) NSString *applicationDirectoryPath;

/** The path to the `ClientDevices` directory. */
@property (nonatomic, readonly) NSString *clientDevicesDirectoryPath;

/** The path to this document's `identifier.plist` file inside the `DeletedDocuments` directory. */
@property (nonatomic, readonly) NSString *deletedDocumentsDirectoryIdentifierPlistFilePath;

/** The path to the `Documents` directory. */
@property (nonatomic, readonly) NSString *documentsDirectoryPath;

/** The path to this document's directory inside the `Documents` directory. */
@property (nonatomic, readonly) NSString *thisDocumentDirectoryPath;

/** The path to this document's `SyncChanges` directory. */
@property (nonatomic, readonly) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path to this client's directory inside this document's `SyncChanges` directory. */
@property (nonatomic, readonly) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

/** The path to this document's `SyncCommands` directory. */
@property (nonatomic, readonly) NSString *thisDocumentSyncCommandsDirectoryPath;

/** The path to this client's directory inside this document's `SyncCommands` directory. */
@property (nonatomic, readonly) NSString *thisDocumentSyncCommandsThisClientDirectoryPath;

/** The path to this client's directory inside the `WholeStore` directory inside this document's `TemporaryFiles` directory. */
@property (nonatomic, readonly) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryPath;

/** The path to this client's temporary `WholeStore.ticdsync` file. */
@property (nonatomic, readonly) NSString *thisDocumentTemporaryWholeStoreFilePath;

/** The path to this client's temporary `AppliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, readonly) NSString *thisDocumentTemporaryAppliedSyncChangeSetsFilePath;

/** The path to this document's `WholeStore` directory. */
@property (nonatomic, readonly) NSString *thisDocumentWholeStoreDirectoryPath;

/** The path to this client's directory inside this document's `WholeStore` directory. */
@property (nonatomic, readonly) NSString *thisDocumentWholeStoreThisClientDirectoryPath;

/** The path to this client's `WholeStore.ticdsync` file. */
@property (nonatomic, readonly) NSString *thisDocumentWholeStoreFilePath;

/** The path to this client's `AppliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, readonly) NSString *thisDocumentAppliedSyncChangeSetsFilePath;

/** The path to this document's `RecentSyncs` directory. */
@property (nonatomic, readonly) NSString *thisDocumentRecentSyncsDirectoryPath;

/** The path to this client's RecentSync file inside this document's `RecentSyncs` directory. */
@property (nonatomic, readonly) NSString *thisDocumentRecentSyncsThisClientFilePath;

@end

#endif