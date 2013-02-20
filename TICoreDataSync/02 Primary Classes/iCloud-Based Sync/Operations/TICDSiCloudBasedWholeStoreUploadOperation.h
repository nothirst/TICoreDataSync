//
//  TICDSiCloudBasedWholeStoreUploadOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSWholeStoreUploadOperation.h"

/**
 `TICDSiCloudBasedWholeStoreUploadOperation` is a "whole store upload" operation designed for use with a `TICDSiCloudBasedDocumentSyncManager`.
 */
@interface TICDSiCloudBasedWholeStoreUploadOperation : TICDSWholeStoreUploadOperation {
@private
    NSString *_thisDocumentTemporaryWholeStoreThisClientDirectoryPath;
    NSString *_thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath;
    NSString *_thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;
    NSString *_thisDocumentWholeStoreThisClientDirectoryPath;
}

/** @name Paths */

/** The path to this client's directory within the `WholeStore` directory inside this document's `TemporaryFiles` directory. */
@property (retain) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryPath;

/** The path to which the whole store file should be copied. */
@property (retain) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath;

/** The path to which the applied sync change sets file should be copied. */
@property (retain) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;

/** The path to this client's directory within this document's `WholeStore` directory. */
@property (retain) NSString *thisDocumentWholeStoreThisClientDirectoryPath;

@end
