//
//  TICDSDropboxSDKBasedDocumentDeletionOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentDeletionOperation.h"

#if TARGET_OS_IPHONE
#import <DropboxSDK/DropboxSDK.h>
#else
#import <DropboxSDK/DropboxOSX.h>
#endif

/**
 `TICDSDropboxSDKBasedDocumentDeletionOperation` is a Document Deletion operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */
@interface TICDSDropboxSDKBasedDocumentDeletionOperation : TICDSDocumentDeletionOperation <DBRestClientDelegate> {
@private
    DBRestClient *_restClient;
    
    NSString *_documentDirectoryPath;
    NSString *_documentInfoPlistFilePath;
    NSString *_deletedDocumentsDirectoryIdentifierPlistFilePath;
}

/** @name Properties */

/** The DropboxSDK `DBRestClient` for use by this operation. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to the directory that should be deleted. */
@property (copy) NSString *documentDirectoryPath;

/** The path to the document's `documentInfo.plist` file. */
@property (copy) NSString *documentInfoPlistFilePath;

/** The path to the document's `identifier.plist` file inside the application's `DeletedDocuments` directory. */
@property (copy) NSString *deletedDocumentsDirectoryIdentifierPlistFilePath;

@end
