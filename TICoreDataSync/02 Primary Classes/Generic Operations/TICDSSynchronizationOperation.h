//
//  TICDSSynchronizationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSSynchronizationOperation` class describes a generic operation used by the `TICoreDataSync` framework to synchronize changes made to a document.
 
 In brief, a synchronization operation pulls down remote sync commands and changes, applies them locally (fixing any conflicts if necessary), and then pushes out the local set of unsynchronized sync changes.
 
 In full, the operation carries out the following tasks:
 
 1. Fetch an array of UUID strings for each available set of `SyncCommand`s.
 2. Determine which sets of `SyncCommand`s haven't yet been applied locally.
 3. If any sets of `SyncCommand`s haven't yet been applied, fetch them to the `UnappliedSyncCommands` helper file directory.
 4. Go through each set of `SyncCommands` and apply them, determining whether synchronization can continue, or whether e.g. the entire store needs to be downloaded.
 5. If synchronization can continue, fetch an array of UUID strings for each available set of `SyncChanges`.
 6. Determine which sets of `SyncChanges` haven't yet been applied locally.
 7. If any sets of `SyncChanges` haven't yet been applied, fetch them to the `UnappliedSyncChanges` helper file directory.
 8. Go through each set of `SyncChanges` and:
     1. Check for conflicts against local changes made since the last synchronization.
     2. Fix any conflicts, and build an array of conflict warnings for issues that cannot be resolved.
     3. Apply each `SyncChange` in the set to the local `WholeStore`.
     4. Add the UUID of the set to the list of `AppliedSyncChanges.sqlite`.
 9. Push any sets of local `SyncCommands` to the remote.
 10. Push any sets of local `SyncChanges` to the remote.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSSynchronizationOperation`. */
@interface TICDSSynchronizationOperation : TICDSOperation {
@private
    
}

@end
