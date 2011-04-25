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
    NSString *_thisDocumentWholeStoreThisClientDirectoryPath;
    NSString *_thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath;
    NSString *_thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;
}

/** @name Paths */

/** The path to this client's directory within this document's `WholeStore` directory. */
@property (retain) NSString *thisDocumentWholeStoreThisClientDirectoryPath;

/** The path to which the whole store file should be copied. */
@property (retain) NSString *thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath;

/** The path to which the applied sync change sets file should be copied. */
@property (retain) NSString *thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;

@end
