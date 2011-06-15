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

/** The DropboxSDK `DBRestClient` for use by this operation. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to the directory that should be deleted. */
@property (retain) NSString *documentDirectoryPath;

/** The path to the document's `documentInfo.plist` file. */
@property (retain) NSString *documentInfoPlistFilePath;

/** The path to the document's `identifier.plist` file inside the application's `DeletedDocuments` directory. */
@property (retain) NSString *deletedDocumentsDirectoryIdentifierPlistFilePath;

@end

#endif