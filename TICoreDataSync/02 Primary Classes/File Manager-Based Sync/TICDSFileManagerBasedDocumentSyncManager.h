//
//  TICDSFileManagerBasedDocumentSyncManager.h
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDocumentSyncManager.h"

/** The `TICDSFileManagerBasedDocumentSyncManager` describes a class used to synchronize documents with a remote service that can be accessed via an `NSFileManager`. This includes:
 
 1. Dropbox (files are typically accessed via `~/Dropbox`)
 2. iDisk
 
 No FileManagerBased-specific settings are required when you create a `TICDSFileManagerBasedDocumentSyncManager`--the `applicationDirectoryPath` is set automatically when you register (based on the properties set on the `TICDSFileManagerBasedApplicationSyncManager`).
 */
@interface TICDSFileManagerBasedDocumentSyncManager : TICDSDocumentSyncManager {
@private
    NSString *_applicationDirectoryPath;
}

/** @name Properties */

/** The path to the root of the application. This will be set automatically when you register and supply a `TICDSFileManagerBasedApplicationSyncManager`. */
@property (nonatomic, retain) NSString *applicationDirectoryPath;

/** @name Paths */

/** The path to the `Documents` directory. */
@property (nonatomic, readonly) NSString *documentsDirectoryPath;

/** The path to this document's directory inside the `Documents` directory. */
@property (nonatomic, readonly) NSString *thisDocumentDirectoryPath;

/** The path to this client's directory inside this document's `SyncChanges` directory. */
@property (nonatomic, readonly) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

@end
