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

@end
