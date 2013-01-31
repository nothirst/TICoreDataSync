//
//  TICDSDropboxSDKBasedPostSynchronizationOperation.h
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICDSPostSynchronizationOperation.h"

#if TARGET_OS_IPHONE
#import <DropboxSDK/DropboxSDK.h>
#else
#import <DropboxSDK/DropboxOSX.h>
#endif

/**
 `TICDSDropboxSDKBasedPostSynchronizationOperation` is a synchronization operation designed for use with a `TICDSDropboxSDKBasedDocumentSyncManager`.
 */

@interface TICDSDropboxSDKBasedPostSynchronizationOperation : TICDSPostSynchronizationOperation <DBRestClientDelegate>

/** @name Properties */

/** The DropboxSDK `DBRestClient` for use by this operation. */
@property (nonatomic, readonly) DBRestClient *restClient;

/** @name Paths */

/** The path to this document's `SyncChanges` directory. */
@property (copy) NSString *thisDocumentSyncChangesDirectoryPath;

/** The path this client's directory inside this document's `SyncChanges` directory. */
@property (copy) NSString *thisDocumentSyncChangesThisClientDirectoryPath;

/** The path this client's RecentSync file inside this document's `RecentSyncs` directory. */
@property (copy) NSString *thisDocumentRecentSyncsThisClientFilePath;

@end

