//
//  TICDSDropboxSDKBasedWholeStoreUploadOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICDSWholeStoreUploadOperation.h"

#if TARGET_OS_IPHONE
#import <DropboxSDK/DropboxSDK.h>
#else
#import <DropboxSDK/DropboxOSX.h>
#endif

/**
 `TICDSDropboxSDKBasedWholeStoreUploadOperation` is a "whole store upload" operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */

@interface TICDSDropboxSDKBasedWholeStoreUploadOperation : TICDSWholeStoreUploadOperation <DBRestClientDelegate> {
@private
    DBRestClient *_restClient;
    
    NSString *_thisDocumentTemporaryWholeStoreThisClientDirectoryPath;
    NSString *_thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath;
    NSString *_thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;
    NSString *_thisDocumentWholeStoreThisClientDirectoryPath;
}

/** @name Properties */

/** The DropboxSDK `DBRestClient` for use by this operation for methods relating to the global application directory. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to this client's directory within the temporary directory in this document's `WholeStore` directory. */
@property (copy) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryPath;

/** The path to which the whole store file should be copied. */
@property (copy) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath;

/** The path to which the applied sync change sets file should be copied. */
@property (copy) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;

/** The path to this client's directory within this document's `WholeStore` directory. */
@property (copy) NSString *thisDocumentWholeStoreThisClientDirectoryPath;

@end

