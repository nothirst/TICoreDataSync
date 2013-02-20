//
//  TICDSPostSynchronizationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSPostSynchronizationOperation` class describes a generic operation used by the `TICoreDataSync` framework to synchronize changes made to a document.
 
 In brief, a post-synchronization operation pushes out the local set of unsynchronized sync changes.
 
 In full, the operation carries out the following tasks: (Sync Command tasks are included below, although not yet implemented)
 
 1. If there are local `SyncCommand`s, rename `UnsynchronizedSyncCommands.ticdsync` to `UUID.synccmd` and push the file to the remote.
 2. If there are local `SyncChange`s, rename `UnsynchronizedSyncChanges.syncchg` to `UUID.syncchd` and push the file to the remote.
 3. Save this client's file in the `RecentSyncs` directory for this document.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSPostSynchronizationOperation`. */
@interface TICDSPostSynchronizationOperation : TICDSOperation

#pragma mark Overridden Methods
/** @name Methods Overridden by Subclasses */

/** Upload the specified sync changes file to the client device's directory inside the document's `SyncChanges` directory.
 
 This method must call `uploadedLocalSyncChangeSetFileSuccessfully:` to indicate whether the creation was successful.
 @param aLocation The location of the file to upload. */
- (void)uploadLocalSyncChangeSetFileAtLocation:(NSURL *)aLocation;

/** Upload the specified RecentSync file to the document's `RecentSync` directory.
 
 This method must call `uploadedRecentSyncFileSuccessfully:` to indicate whether the creation was successful.
 
 @param aLocation The location of the file to upload. */
- (void)uploadRecentSyncFileAtLocation:(NSURL *)aLocation;

#pragma mark Callbacks
/** @name Callbacks */

/** Indicate whether the upload of the sync change set file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the sync change set file was uploaded, otherwise `NO`. */
- (void)uploadedLocalSyncChangeSetFileSuccessfully:(BOOL)success;

/** Indicate whether the upload of the RecentSync file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the RecentSync file was uploaded, otherwise `NO`. */
- (void)uploadedRecentSyncFileSuccessfully:(BOOL)success;

/** @name File Locations */

/** The location of the `SyncChangesBeingSynchronized.syncchg` file for this synchronization operation. */
@property (strong) NSURL *localSyncChangesToMergeURL;

/** The location of the local RecentSync file to upload at the end of the synchronization process. */
@property (strong) NSURL *localRecentSyncFileLocation;

/** The location of this document's `AppliedSyncChangeSets.ticdsync` file. */
@property (strong) NSURL *appliedSyncChangeSetsFileLocation;

@end
