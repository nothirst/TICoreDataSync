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
    NSDate *_earliestDateForFilesToKeep;
}

/** @name Methods Overridden by Subclasses */

/** Determine the modification date of the oldest `WholeStore` file uploaded by any client.
 
 This method must call `foundOutDateOfOldestWholeStoreFile:` when finished. */
- (void)findOutDateOfOldestWholeStore;

/** Determine the date on which the least-recently-synchronized client last performed a sync.
 
 This method must call `foundOutLeastRecentClientSyncDate:` when finished. */
- (void)findOutLeastRecentClientSyncDate;

/** Remove all `SyncChangeSet` files uploaded by this client which are older than `earliestDateForFilesToKeep`.
 
 This method must call `removedOldSyncChangeSetFilesWithSuccess:` when finished. */
- (void)removeOldSyncChangeSetFiles;

/** @name Callbacks */

/** Indicate the date of the oldest `WholeStore` file.
 
 If an error occurs, call `setError:` first, then specify `nil` for `aDate`. If no client has uploaded a `WholeStore`, specify `[NSDate date]`.
 
 @param aDate The modification date of the oldest `WholeStore` file. */
- (void)foundOutDateOfOldestWholeStoreFile:(NSDate *)aDate;
 
/** Indicate the date of the least recent sync.
 
 If an error occurs, call `setError:` first, then specify `nil` for `aDate`.
 
 @param aDate The date of the least recent sync. */
- (void)foundOutLeastRecentClientSyncDate:(NSDate *)aDate;

/** Indicate whether the removal of old `SyncChangeSet` files was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the old sync change set files for this operation were removed, otherwise `NO`. */
- (void)removedOldSyncChangeSetFilesWithSuccess:(BOOL)success;

/** @name Properties */

/** The earliest modification date after which files must be kept. */
@property (nonatomic, strong ) NSDate *earliestDateForFilesToKeep;

@end
