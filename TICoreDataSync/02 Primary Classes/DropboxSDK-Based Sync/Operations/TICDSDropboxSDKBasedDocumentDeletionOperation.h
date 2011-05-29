//
//  TICDSDropboxSDKBasedDocumentDeletionOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICDSDocumentDeletionOperation.h"
#import "DropboxSDK.h"

/**
 `TICDSDropboxSDKBasedDocumentDeletionOperation` is a Document Deletion operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */
@interface TICDSDropboxSDKBasedDocumentDeletionOperation : TICDSDocumentDeletionOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_restClient;
    
    NSString *_documentDirectoryPath;
    NSString *_documentInfoPlistFilePath;
    NSString *_deletedDocumentsDirectoryIdentifierPlistFilePath;
}

/** @name Properties */

/** The DropboxSDK `DBSession` for use by this operation's `DBRestClient`. */
@property (retain) DBSession *dbSession;

/** The DropboxSDK `DBRestClient` for use by this operation for methods relating to the global application directory. */
@property (nonatomic, retain) DBRestClient *restClient;

@property (retain) NSString *documentDirectoryPath;
@property (retain) NSString *documentInfoPlistFilePath;
@property (retain) NSString *deletedDocumentsDirectoryIdentifierPlistFilePath;

@end

#endif