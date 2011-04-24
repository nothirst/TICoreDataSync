//
//  TICDSFileManagerBasedDocumentRegistrationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentRegistrationOperation.h"

/**
 `TICDSFileManagerBasedDocumentRegistrationOperation` is a document registration operation designed for use with a `TICDSFileManagerBasedDocumentSyncManager`.
 */

@interface TICDSFileManagerBasedDocumentRegistrationOperation : TICDSDocumentRegistrationOperation {
@private
    NSString *_documentsDirectoryPath;
    NSString *_thisDocumentDirectoryPath;
    NSString *_thisDocumentSyncChangesThisClientDirectoryPath;
}

/** @name Paths */

/** The path to the `Documents` directory. */
@property (retain) NSString *documentsDirectoryPath;

/** The path to this document's directory inside the `Documents` directory. */
@property (retain) NSString *thisDocumentDirectoryPath;

/** The path to the this client's directory inside this document's `SyncChanges` directory. */
@property (retain) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

@end
