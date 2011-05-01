//
//  TICDSFileManagerBasedVacuumOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 29/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSVacuumOperation.h"


/**
 `TICDSFileManagerBasedVacuumOperation` is a vacuum operation designed for use with a `TICDSFileManagerBasedDocumentSyncManager`.
 */

@interface TICDSFileManagerBasedVacuumOperation : TICDSVacuumOperation {
@private
    NSString *_thisDocumentWholeStoreDirectoryPath;
    NSString *_thisDocumentRecentSyncsDirectoryPath;
    NSString *_thisDocumentSyncChangesThisClientDirectoryPath;
}

/** @name Paths */

/** The path to a given client's `WholeStore.ticdsync` file within this document's `WholeStore` directory. */
- (NSString *)pathToWholeStoreFileForClientWithIdentifier:(NSString *)anIdentifier;

/** The path to this document's `WholeStore` directory. */
@property (retain) NSString *thisDocumentWholeStoreDirectoryPath;

/** The path to this document's `RecentSyncs` directory. */
@property (retain) NSString *thisDocumentRecentSyncsDirectoryPath;

/** The path to this client's directory inside the `RecentSyncs` directory for this document. */
@property (retain) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

@end
