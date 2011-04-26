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
 
 1. Fetch an array containing UUID strings for each client device that has synchronized this document.
 2. For each client device that isn't the current device:
     1. Fetch an array containing UUID strings for each available `SyncCommandSet`.
 2. Determine which `SyncCommandSet`s haven't yet been applied locally.
 3. If any `SyncCommandSet`s haven't yet been applied, fetch them to the `UnappliedSyncCommandSets` helper file directory.
 4. Go through each `SyncCommandSet` and:
     1. Carry out the command, determining whether synchronization can continue, or whether e.g. the entire store needs to be downloaded.
     2. Add the UUID of the set to the list of `AppliedSyncChangeCommands.sqlite`.
 5. If synchronization can continue, then for each client device that isn't the current device:
     1. Fetch an array containing UUID strings for each available `SyncChangeSet`.
     2. Determine which `SyncChangeSet`s haven't yet been applied locally.
     3. If any `SyncChangeSet`s haven't yet been applied, fetch them to the `UnappliedSyncChangeSets` helper file directory.
 6. Go through each `SyncChangeSet` and:
     1. Check for conflicts against local changes made since the last synchronization.
     2. Fix any conflicts, and build an array of conflict warnings for issues that cannot be resolved.
     3. Apply each `SyncChange` in the set to the local `WholeStore`.
     4. Add the UUID of the set to the list of `AppliedSyncChangeSets.sqlite`.
 7. If there are local `SyncCommand`s, rename `UnsynchronizedSyncCommands.sqlite` to `UUID.synccmd` and push the file to the remote.
 8. If there are local `SyncChange`s, rename `UnsynchronizedSyncChanges.sqlite` to `UUID.syncchd` and push the file to the remote.
 9. Save this client's file in the `RecentSyncs` directory for this document.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSSynchronizationOperation`. */
@interface TICDSSynchronizationOperation : TICDSOperation {
@private
    NSArray *_otherSynchronizedClientDeviceIdentifiers;
    NSMutableArray *_otherSynchronizedClientDeviceSyncChangeSetIdentifiers;
    
    NSURL *_localSyncChangesToMergeLocation;
    NSURL *_appliedSyncChangeSetsFileLocation;
    
    BOOL _completionInProgress;
    TICDSOperationPhaseStatus _fetchArrayOfClientDeviceIDsStatus;
    TICDSOperationPhaseStatus _fetchArrayOfSyncCommandSetIDsStatus;
    
    NSUInteger _numberOfSyncChangeSetIDArraysToFetch;
    NSUInteger _numberOfSyncChangeSetIDArraysFetched;
    NSUInteger _numberOfSyncChangeSetIDArraysThatFailedToFetch;
    TICDSOperationPhaseStatus _fetchArrayOfSyncChangeSetIDsStatus;
    
    NSUInteger _numberOfUnappliedSyncChangeSetsToFetch;
    NSUInteger _numberOfUnappliedSyncChangeSetsFetched;
    NSUInteger _numberOfUnappliedSyncChangeSetsThatFailedToFetch;
    TICDSOperationPhaseStatus _fetchUnappliedSyncChangeSetsStatus;
    
    TICDSOperationPhaseStatus _uploadLocalSyncCommandSetStatus;
    TICDSOperationPhaseStatus _uploadLocalSyncChangeSetStatus;
}

#pragma mark Overridden Methods
/** @name Methods Overridden by Subclasses */

/** Build an array of `NSString` identifiers for all clients that have synchronized with this document. 
 
 Call `builtArrayOfClientDeviceIdentifiers:` when the array is built. */
- (void)buildArrayOfClientDeviceIdentifiers;

/** Build an array of `NSString` identifiers for each `SyncChangeSet` for the given client device.
 
 Call `builtArrayOfClientSyncChangeSetIdentifiers:forClientIdentifier:` when the array is built.
 
 @param anIdentifier The unique identifier of the client. */
- (void)buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:(NSString *)anIdentifier;

/** Upload the specified sync changes file to the client device's directory inside the document's `SyncChanges` directory.
 
 This method must call `uploadedLocalSyncChangeSetFileSuccessfully:` to indicate whether the creation was successful.
 */
- (void)uploadLocalSyncChangeSetFileAtLocation:(NSURL *)aLocation;

#pragma mark Callbacks
/** @name Callbacks */

/** Pass back the assembled `NSArray` of `NSString` `ClientDevice` identifiers.
 
 If an error occurred, call `setError:` first, then specify `nil` for `anArray`.
 
 @param anArray The array of identifiers. Pass `nil` if an error occurred. */
- (void)builtArrayOfClientDeviceIdentifiers:(NSArray *)anArray;

/** Pass back the assembled `NSArray` of `NSString` `SyncChangeSet` identifiers.
 
 If an error occured, call `setError:` first, then specify `nil` for `anArray`.
 
 @param anArray The array of identifiers. Pass `nil` if an error occurred.
 @param anIdentifier The client identifier for this array of `SyncChangeSet` identifiers. */
- (void)builtArrayOfClientSyncChangeSetIdentifiers:(NSArray *)anArray forClientIdentifier:(NSString *)anIdentifier;

/** Indicate whether the upload of the sync change set file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success A Boolean indicating whether the sync change set file was uploaded or not. */
- (void)uploadedLocalSyncChangeSetFileSuccessfully:(BOOL)success;

#pragma mark Properties
/** @name Properties */

/** The location of the `SyncChangesBeingSynchronized.sqlite` file for this synchronization operation. */
@property (retain) NSURL *localSyncChangesToMergeLocation;

/** The location of this document's `AppliedSyncChangeSets.sqlite` file. */
@property (retain) NSURL *appliedSyncChangeSetsFileLocation;

/** An array of client identifiers for clients that synchronize with this document, excluding this client. */
@property (nonatomic, retain) NSArray *otherSynchronizedClientDeviceIdentifiers;

/** An array of sync change set identifiers from other clients that synchronize with this document. */
@property (retain) NSMutableArray *otherSynchronizedClientDeviceSyncChangeSetIdentifiers;

#pragma mark Completion
/** @name Completion */

/** Used to indicate that completion is currently in progress, and that no further checks should be made. */
@property (nonatomic, assign) BOOL completionInProgress;

/** The phase status regarding fetching an array of client devices that have synchronized this document. */
@property (nonatomic, assign) TICDSOperationPhaseStatus fetchArrayOfClientDeviceIDsStatus;

/** The phase status regarding fetching an array of available SyncCommand sets. */
@property (nonatomic, assign) TICDSOperationPhaseStatus fetchArrayOfSyncCommandSetIDsStatus;

/** The total number of arrays of `SyncChangeSet` identifiers that need to be fetched. */
@property (nonatomic, assign) NSUInteger numberOfSyncChangeSetIDArraysToFetch;

/** The number of arrays of `SyncChangeSet` identifiers that have already been fetched. */
@property (nonatomic, assign) NSUInteger numberOfSyncChangeSetIDArraysFetched;

/** The number of arrays of `SyncChangeSet` identifiers that failed to fetch because of an error. */
@property (nonatomic, assign) NSUInteger numberOfSyncChangeSetIDArraysThatFailedToFetch;

/** The phase status regarding fetching an array of available `SyncChangeSet` identifiers. */
@property (nonatomic, assign) TICDSOperationPhaseStatus fetchArrayOfSyncChangeSetIDsStatus;

/** The phase status regarding fetching all unapplied `SyncChangeSet`s. */
@property (nonatomic, assign) TICDSOperationPhaseStatus fetchUnappliedSyncChangeSetsStatus;

/** The phase status regarding upload of the local set of sync commands. */
@property (nonatomic, assign) TICDSOperationPhaseStatus uploadLocalSyncCommandSetStatus;

/** THe phase status regarding upload of the local set of sync changes. */
@property (nonatomic, assign) TICDSOperationPhaseStatus uploadLocalSyncChangeSetStatus;

@end
