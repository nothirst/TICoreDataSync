//
//  TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICDSListOfPreviouslySynchronizedDocumentsOperation.h"
#import "DropboxSDK.h"

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

/** The DropboxSDK `DBRestClient` for use by this operation for methods relating to the global application directory. */
@property (nonatomic, retain) DBRestClient *restClient;

@property (nonatomic, retain) NSString *thisDocumentSyncChangesDirectoryPath;
@property (nonatomic, retain) NSString *clientDevicesDirectoryPath;
@property (nonatomic, retain) NSString *thisDocumentRecentSyncsDirectoryPath;
@property (nonatomic, retain) NSString *thisDocumentWholeStoreDirectoryPath;

- (NSString *)pathToInfoDictionaryForDeviceWithIdentifier:(NSString *)anIdentifier;
- (NSString *)pathToWholeStoreFileForDeviceWithIdentifier:(NSString *)anIdentifier;

@end

#endif