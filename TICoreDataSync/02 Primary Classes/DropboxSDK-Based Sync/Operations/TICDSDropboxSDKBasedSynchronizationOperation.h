//
//  TICDSDropboxSDKBasedSynchronizationOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSSynchronizationOperation.h"
#import "DropboxSDK.h"


@interface TICDSDropboxSDKBasedSynchronizationOperation : TICDSSynchronizationOperation <DBRestClientDelegate> {
@private
    DBSession *_dbSession;
    DBRestClient *_restClient;
    
    NSMutableDictionary *_clientIdentifiersForChangeSetIdentifiers;
    NSMutableDictionary *_changeSetModificationDates;
    
    NSString *_thisDocumentSyncChangesDirectoryPath;
    NSString *_thisDocumentSyncChangesThisClientDirectoryPath;
    NSString *_thisDocumentRecentSyncsThisClientFilePath;
}

/** @name Properties */

/** The DropboxSDK `DBSession` for use by this operation's `DBRestClient`. */
@property (retain) DBSession *dbSession;

/** The DropboxSDK `DBRestClient` for use by this operation for methods relating to the global application directory. */
@property (nonatomic, retain) DBRestClient *restClient;

/** A dictionary used to find out the client responsible for creating a change set. */
@property (nonatomic, retain) NSMutableDictionary *clientIdentifiersForChangeSetIdentifiers;

/** A dictionary used to keep hold of the modification dates of sync change sets. */
@property (nonatomic, retain) NSMutableDictionary *changeSetModificationDates;

/** @name Paths */

/** The path to this document's `SyncChanges` directory. */
@property (retain) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path this client's directory inside this document's `SyncChanges` directory. */
@property (retain) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

/** The path this client's RecentSync file inside this document's `RecentSyncs` directory. */
@property (retain) NSString *thisDocumentRecentSyncsThisClientFilePath;

/** The path to a given client's `SyncChanges` directory.
 
 @param anIdentifier The unique sync identifier of the document. */
- (NSString *)pathToSyncChangesDirectoryForClientWithIdentifier:(NSString *)anIdentifier;

/** The path to a `SyncChangeSet` uploaded by a given client.
 
 @param aChangeSetIdentifier The unique identifier of the sync change set.
 @param aClientIdentifier The unique sync identifier of the client. */
- (NSString *)pathToSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientWithIdentifier:(NSString *)aClientIdentifier;

@end
