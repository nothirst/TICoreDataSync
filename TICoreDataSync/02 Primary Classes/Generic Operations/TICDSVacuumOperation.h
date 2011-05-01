//
//  TICDSVacuumOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 29/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSVacuumOperation` class describes a generic operation used by the `TICoreDataSync` framework to clean up unneeded files used to synchronize documents.
 
 The operation carries out the following tasks:
 
 1. Find out the date of the oldest `WholeStore`.
 2. Find out the date of the least recent client sync.
 3. Remove all `SyncChangeSet` files older than whichever date is earlier.
 
 Currently unimplemented, it also needs to carry out the following:
 1. Create sync commands to remove the ids of these sync change sets from each client's `AppliedSyncChangeSets.ticdsync` file.
 2. Remove all `SyncCommandSet` files older than the least recent sync.
 3. Create sync commands to remove the ids of these sync command sets from each client's `AppliedSyncCommandSets.ticdsync` file.
 
 Operations are typically created automatically by the relevant document sync manager.
 
 @warning You must use one of the subclasses of `TICDSVacuumOperation`. */

@interface TICDSVacuumOperation : TICDSOperation {
@private
    NSDate *_leastRecentClientSyncDate;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _findOutLeastRecentClientSyncDateStatus;
    TICDSOperationPhaseStatus _removeOldSyncChangeSetFilesStatus;
}

/** @name Methods Overridden by Subclasses */

/** Determine the date on which the least-recently-synchronized client last performed a sync.
 
 This method must call `foundOutLeastRecentClientSyncDate:` when finished. */
- (void)findOutLeastRecentClientSyncDate;

/** Remove all `SyncChangeSet` files uploaded by this client which are older than `leastRecentClientSyncDate`.
 
 This method must call `removedOldSyncChangeSetFilesWithSuccess:` when finished. */
- (void)removeOldSyncChangeSetFiles;

/** @name Callbacks */

/** Indicate the date of the least recent sync.
 
 If an error occurs, call `setError:` first, then specify `nil` for `aDate`.
 
 @param aDate The date of the least recent sync. */
- (void)foundOutLeastRecentClientSyncDate:(NSDate *)aDate;

/** Indicate whether the removal of old `SyncChangeSet` files was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the old sync change set files for this operation were removed or not. */
- (void)removedOldSyncChangeSetFilesWithSuccess:(BOOL)success;

/** @name Properties */

/** The date of the least recent client sync. */
@property (nonatomic, retain ) NSDate *leastRecentClientSyncDate;

/** @name Completion */

/** Used to indicate that completion is currently in progress, and that no further checks should be made. */
@property (nonatomic, assign) BOOL completionInProgress;

/** The phase status regarding finding out the date of the oldest file in the `RecentSyncs` directory. */
@property (nonatomic, assign) TICDSOperationPhaseStatus findOutLeastRecentClientSyncDateStatus;

/** The phase status regarding finding removing old, unneeded sync change set files from this client. */
@property (nonatomic, assign) TICDSOperationPhaseStatus removeOldSyncChangeSetFilesStatus;

@end
