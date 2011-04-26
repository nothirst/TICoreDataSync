//
//  TICDSFileManagerBasedSynchronizationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSSynchronizationOperation.h"

/**
 `TICDSFileManagerBasedSynchronizationOperation` is a synchronization operation designed for use with a `TICDSFileManagerBasedDocumentSyncManager`.
 */

@interface TICDSFileManagerBasedSynchronizationOperation : TICDSSynchronizationOperation {
@private
    NSString *_thisDocumentSyncChangesDirectoryPath;
}

/** @name Paths */

/** The path to this document's `SyncChanges` directory. */
@property (retain) NSString *thisDocumentSyncChangesDirectoryPath;

@end
