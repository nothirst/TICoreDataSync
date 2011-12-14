//
//  TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICDSListOfPreviouslySynchronizedDocumentsOperation.h"
#import <DropboxSDK/DropboxSDK.h>

/**
 `TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation` is a "List of Registered Clients for a Document" operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */
@interface TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation : TICDSListOfDocumentRegisteredClientsOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_restClient;
    
    NSString *_thisDocumentSyncChangesDirectoryPath;
    NSString *_clientDevicesDirectoryPath;
    NSString *_thisDocumentRecentSyncsDirectoryPath;
    NSString *_thisDocumentWholeStoreDirectoryPath;
}

/** @name Properties */

/** The DropboxSDK `DBSession` for use by this operation's `DBRestClient`. */
@property (retain) DBSession *dbSession;

/** The DropboxSDK `DBRestClient` for use by this operation. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to this document's `SyncChanges` directory. */
@property (nonatomic, retain) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path to the application's `ClientDevices` directory. */
@property (nonatomic, retain) NSString *clientDevicesDirectoryPath;

/** The path to this document's `RecentSyncs` directory. */
@property (nonatomic, retain) NSString *thisDocumentRecentSyncsDirectoryPath;

/** The path to this document's `WholeStore` directory. */
@property (nonatomic, retain) NSString *thisDocumentWholeStoreDirectoryPath;

/** Return the path to the `deviceInfo.plist` file for a given client identifier.
 
 @param anIdentifier The synchronization identifier of the client.
 
 @return The path to the client's `deviceInfo.plist` file. */
- (NSString *)pathToInfoDictionaryForDeviceWithIdentifier:(NSString *)anIdentifier;

/** Return the path to the `WholeStore.ticdsync` file uploaded for this document by a given client. 
 
 @param anIdentifier The synchronization identifier of the client. 
 
 @return The path to the client's `WholeStore.ticdsync` file. */
- (NSString *)pathToWholeStoreFileForDeviceWithIdentifier:(NSString *)anIdentifier;

@end

#endif