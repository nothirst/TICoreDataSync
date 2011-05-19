//
//  TICDSDropboxSDKBasedWholeStoreUploadOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICDSWholeStoreUploadOperation.h"
#import "DropboxSDK.h"

/**
 `TICDSDropboxSDKBasedWholeStoreUploadOperation` is a "whole store upload" operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */

@interface TICDSDropboxSDKBasedWholeStoreUploadOperation : TICDSWholeStoreUploadOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_restClient;
    
    NSString *_thisDocumentWholeStoreThisClientDirectoryPath;
    NSString *_thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath;
    NSString *_thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;
}

/** @name Properties */

/** The DropboxSDK `DBSession` for use by this operation's `DBRestClient`. */
@property (retain) DBSession *dbSession;

/** The DropboxSDK `DBRestClient` for use by this operation for methods relating to the global application directory. */
@property (nonatomic, retain) DBRestClient *restClient;

/** @name Paths */

/** The path to this client's directory within this document's `WholeStore` directory. */
@property (retain) NSString *thisDocumentWholeStoreThisClientDirectoryPath;

/** The path to which the whole store file should be copied. */
@property (retain) NSString *thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath;

/** The path to which the applied sync change sets file should be copied. */
@property (retain) NSString *thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;

@end

#endif