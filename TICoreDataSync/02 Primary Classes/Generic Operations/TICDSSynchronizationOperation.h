//
//  TICDSSynchronizationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSSynchronizationOperation` class describes a generic operation used by the `TICoreDataSync` framework to synchronize changes made to a document.
 
 In brief, a synchronization operation applies remote sync commands and changes locally, fixing any conflicts if necessary.
 
 In full, the operation carries out the following tasks: (Sync Command tasks are included below, although not yet implemented)
 
 1. Go through each `SyncChangeSet` and:
     1. Check for conflicts against local changes made since the last synchronization.
     2. Fix any conflicts, and build an array of conflict warnings for issues that cannot be resolved.
     3. Apply each `SyncChange` in the set to the local `WholeStore`.
     4. Add the UUID of the set to the list of `AppliedSyncChangeSets.ticdsync`.
 
 Operations are typically created automatically by the relevant sync manager.
 
 You need not use one of the subclasses of `TICDSSynchronizationOperation`. */
@interface TICDSSynchronizationOperation : TICDSOperation

#pragma mark Designated Initializer
/** @name Designated Initializer */

/** Initialize a synchronization operation using a delegate that supports the `TICDSSynchronizationOperationDelegate` protocol.
 
 @param aDelegate The delegate to use for this operation.
 
 @return An initialized synchronization operation. */
- (id)initWithDelegate:(NSObject<TICDSSynchronizationOperationDelegate> *)aDelegate;

#pragma mark Helper Methods

#pragma mark Configuration
/** Configure a background context (for applying sync changes) using the same persistent store coordinator as the main application context.
 
 @param aPersistentStoreCoordinator The persistent store coordinator to use for the background context. */
- (void)configureBackgroundApplicationContextForPrimaryManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

#pragma mark Properties
/** @name Properties */

/** The warnings generated during this synchronization. */
@property (strong) NSMutableArray *synchronizationWarnings;

/** A boolean indicating whether the operation is currently paused awaiting an instruction to continue, e.g. for conflict resolution. */
@property (assign, getter = isPaused) BOOL paused;

/** The resolution type for the most recent conflict, set before resuming the operation after a conflict is detected. */
@property (assign) TICDSSyncConflictResolutionType mostRecentConflictResolutionType;

/** @name File Locations */

/** The location of the `SyncChangesBeingSynchronized.syncchg` file for this synchronization operation. */
@property (strong) NSURL *localSyncChangesToMergeURL;

/** The location of this document's `AppliedSyncChangeSets.ticdsync` file. */
@property (strong) NSURL *appliedSyncChangeSetsFileLocation;

/** The location of the `UnappliedSyncChanges` directory for this synchronization operation. */
@property (strong) NSURL *unappliedSyncChangesDirectoryLocation;

/** The location of this document's `UnappliedSyncChangeSets.ticdsync` file. */
@property (strong) NSURL *unappliedSyncChangeSetsFileLocation;

/** The sync transaction to be used by this operation. */
@property TICDSSyncTransaction *syncTransaction;

/** The sync transactions whose unsaved applied sync change files will be used as persistent stores to augment the applied sync changes managed object context. */
@property NSArray *syncTransactions;

@end
