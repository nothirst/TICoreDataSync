//
//  TICDSFileManagerBasedWholeStoreUploadOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSWholeStoreUploadOperation.h"

/**
 `TICDSFileManagerBasedWholeStoreUploadOperation` is a "whole store upload" operation designed for use with a `TICDSFileManagerBasedDocumentSyncManager`.
 */
@interface TICDSFileManagerBasedWholeStoreUploadOperation : TICDSWholeStoreUploadOperation {
@private
    NSString *_thisDocumentTemporaryWholeStoreThisClientDirectoryPath;
    NSString *_thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath;
    NSString *_thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;
    NSString *_thisDocumentWholeStoreThisClientDirectoryPath;
}

/** @name Paths */

/** The path to this client's directory within the `WholeStore` directory inside this document's `TemporaryFiles` directory. */
@property (copy) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryPath;

/** The path to which the whole store file should be copied. */
@property (copy) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath;

/** The path to which the applied sync change sets file should be copied. */
@property (copy) NSString *thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;

/** The path to this client's directory within this document's `WholeStore` directory. */
@property (copy) NSString *thisDocumentWholeStoreThisClientDirectoryPath;

@end
