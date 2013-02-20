//
//  TICDSFileManagerBasedPreSynchronizationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSSynchronizationOperation.h"

/**
 `TICDSFileManagerBasedPreSynchronizationOperation` is a synchronization operation designed for use with a `TICDSFileManagerBasedDocumentSyncManager`.
 */

@interface TICDSFileManagerBasedPreSynchronizationOperation : TICDSPreSynchronizationOperation {
@private
    NSString *_thisDocumentDirectoryPath;
    NSString *_thisDocumentSyncChangesDirectoryPath;
    NSString *_thisDocumentSyncChangesThisClientDirectoryPath;
    NSString *_thisDocumentRecentSyncsThisClientFilePath;
}

/** @name Paths */

/** The path to this document's directory. */
@property (copy) NSString *thisDocumentDirectoryPath;

/** The path to this document's `SyncChanges` directory. */
@property (copy) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path this client's directory inside this document's `SyncChanges` directory. */
@property (copy) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

/** The path this client's RecentSync file inside this document's `RecentSyncs` directory. */
@property (copy) NSString *thisDocumentRecentSyncsThisClientFilePath;

/** The path to a given client's `SyncChanges` directory.
 
 @param anIdentifier The unique sync identifier of the document. */
- (NSString *)pathToSyncChangesDirectoryForClientWithIdentifier:(NSString *)anIdentifier;

/** The path to a `SyncChangeSet` uploaded by a given client.
 
 @param aChangeSetIdentifier The unique identifier of the sync change set.
 @param aClientIdentifier The unique sync identifier of the client. */
- (NSString *)pathToSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientWithIdentifier:(NSString *)aClientIdentifier;

@end
