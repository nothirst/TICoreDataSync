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
 
 In full, the operation carries out the following tasks: (Sync Command tasks are included below, although not yet implemented)
 
 1. Fetch an array containing UUID strings for each client device that has synchronized this document.
 2. For each client device that isn't the current device:
     1. Fetch an array containing UUID strings for each available `SyncCommandSet`.
 2. Determine which `SyncCommandSet`s haven't yet been applied locally.
 3. If any `SyncCommandSet`s haven't yet been applied, fetch them to the `UnappliedSyncCommandSets` helper file directory.
 4. Go through each `SyncCommandSet` and:
     1. Carry out the command, determining whether synchronization can continue, or whether e.g. the entire store needs to be downloaded.
     2. Add the UUID of the set to the list of `AppliedSyncCommands.ticdsync`.
 5. If synchronization can continue, then for each client device that isn't the current device:
     1. Fetch an array containing UUID strings for each available `SyncChangeSet`.
     2. Determine which `SyncChangeSet`s haven't yet been applied locally.
     3. If any `SyncChangeSet`s haven't yet been applied, fetch them to the `UnappliedSyncChangeSets` helper file directory.
 6. Go through each `SyncChangeSet` and:
     1. Check for conflicts against local changes made since the last synchronization.
     2. Fix any conflicts, and build an array of conflict warnings for issues that cannot be resolved.
     3. Apply each `SyncChange` in the set to the local `WholeStore`.
     4. Add the UUID of the set to the list of `AppliedSyncChangeSets.ticdsync`.
 7. If there are local `SyncCommand`s, rename `UnsynchronizedSyncCommands.ticdsync` to `UUID.synccmd` and push the file to the remote.
 8. If there are local `SyncChange`s, rename `UnsynchronizedSyncChanges.syncchg` to `UUID.syncchd` and push the file to the remote.
 9. Save this client's file in the `RecentSyncs` directory for this document.
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSSynchronizationOperation`. */
@interface TICDSSynchronizationOperation : TICDSOperation {
@private
    BOOL _paused;
    TICDSSyncConflictResolutionType _mostRecentConflictResolutionType;
    
    NSArray *_otherSynchronizedClientDeviceIdentifiers;
    NSMutableDictionary *_otherSynchronizedClientDeviceSyncChangeSetIdentifiers;
    NSArray *_syncChangeSortDescriptors;
    NSMutableArray *_synchronizationWarnings;
    
    NSURL *_localSyncChangesToMergeLocation;
    NSURL *_appliedSyncChangeSetsFileLocation;
    NSURL *_unappliedSyncChangesDirectoryLocation;
    NSURL *_unappliedSyncChangeSetsFileLocation;
    NSURL *_localRecentSyncFileLocation;
    
    TICoreDataFactory *_appliedSyncChangeSetsCoreDataFactory;
    NSManagedObjectContext *_appliedSyncChangeSetsContext;
    
    TICoreDataFactory *_unappliedSyncChangeSetsCoreDataFactory;
    NSManagedObjectContext *_unappliedSyncChangeSetsContext;
    
    TICoreDataFactory *_unappliedSyncChangesCoreDataFactory;
    NSManagedObjectContext *_unappliedSyncChangesContext;
    
    TICoreDataFactory *_localSyncChangesToMergeCoreDataFactory;
    NSManagedObjectContext *_localSyncChangesToMergeContext;
    
    NSPersistentStoreCoordinator *_primaryPersistentStoreCoordinator;
    TICDSSynchronizationOperationManagedObjectContext *_backgroundApplicationContext;
    
    NSUInteger _numberOfSyncChangeSetIDArraysToFetch;
    NSUInteger _numberOfSyncChangeSetIDArraysFetched;
    NSUInteger _numberOfSyncChangeSetIDArraysThatFailedToFetch;
    
    NSUInteger _numberOfUnappliedSyncChangeSetsToFetch;
    NSUInteger _numberOfUnappliedSyncChangeSetsFetched;
    NSUInteger _numberOfUnappliedSyncChangeSetsThatFailedToFetch;
    
    NSString *_integrityKey;
	NSString *_changeSetProgressString;
	NSNumberFormatter *_uuidPrefixFormatter;
}

#pragma mark Designated Initializer
/** @name Designated Initializer */

/** Initialize a synchronization operation using a delegate that supports the `TICDSSynchronizationOperationDelegate` protocol.
 
 @param aDelegate The delegate to use for this operation.
 
 @return An initialized synchronization operation. */
- (id)initWithDelegate:(NSObject<TICDSSynchronizationOperationDelegate> *)aDelegate;

#pragma mark Overridden Methods
/** @name Methods Overridden by Subclasses */

/** Fetch the integrity key for this document.
 
 This method must call `fetchedRemoteIntegrityKey:` to provide the key. */
- (void)fetchRemoteIntegrityKey;

/** Build an array of `NSString` identifiers for all clients that have synchronized with this document. 
 
 Call `builtArrayOfClientDeviceIdentifiers:` when the array is built. */
- (void)buildArrayOfClientDeviceIdentifiers;

/** Build an array of `NSString` identifiers for each `SyncChangeSet` for the given client device.
 
 Call `builtArrayOfClientSyncChangeSetIdentifiers:forClientIdentifier:` when the array is built.
 
 @param anIdentifier The unique identifier of the client. */
- (void)buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:(NSString *)anIdentifier;

/** Fetch a `SyncChangeSet` with a given identifier from a client's `SyncChanges` directory.
 
 This method must call `fetchedSyncChangeSetsWithIdentifier:forClientIdentifier:withSuccess:` when finished. 
 
 @param aChangeSetIdentifier The identifier of the sync change set to fetch.
 @param aClientIdentifier The identifier of the client who created the sync change set.
 @param aLocation The location of the file to upload. */
- (void)fetchSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientIdentifier:(NSString *)aClientIdentifier toLocation:(NSURL *)aLocation;

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

/** Pass back the remote integrity key for this document.
 
 If an error occurred, call `setError:` first, then specify `nil` for `aKey`.
 
 @param aKey The remote integrity key, or `nil` if an error occurred. */
- (void)fetchedRemoteIntegrityKey:(NSString *)aKey;

/** Pass back the assembled `NSArray` of `NSString` `ClientDevice` identifiers.
 
 If an error occurred, call `setError:` first, then specify `nil` for `anArray`.
 
 @param anArray The array of identifiers. Pass `nil` if an error occurred. */
- (void)builtArrayOfClientDeviceIdentifiers:(NSArray *)anArray;

/** Pass back the assembled `NSArray` of `NSString` `SyncChangeSet` identifiers.
 
 If an error occured, call `setError:` first, then specify `nil` for `anArray`.
 
 @param anArray The array of identifiers. Pass `nil` if an error occurred.
 @param anIdentifier The client identifier for this array of `SyncChangeSet` identifiers. */
- (void)builtArrayOfClientSyncChangeSetIdentifiers:(NSArray *)anArray forClientIdentifier:(NSString *)anIdentifier;

/** Indicate whether the download of the specified `SyncChangeSet` was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 If it was successful, you should supply the original modification date of the file.
 
 @param aChangeSetIdentifier The identifier for the change set to fetch.
 @param aClientIdentifier The identifier of the client who uploaded the change set.
 @param aDate The modification date of the change set.
 @param success A Boolean indicating whether the sync change set file was downloaded or not. */
- (void)fetchedSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientIdentifier:(NSString *)aClientIdentifier modificationDate:(NSDate *)aDate withSuccess:(BOOL)success;

/** Indicate whether the upload of the sync change set file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the sync change set file was uploaded, otherwise `NO`. */
- (void)uploadedLocalSyncChangeSetFileSuccessfully:(BOOL)success;

/** Indicate whether the upload of the RecentSync file was successful.
 
 If not, call `setError:` first, then specify `NO` for `success`.
 
 @param success `YES` if the RecentSync file was uploaded, otherwise `NO`. */
- (void)uploadedRecentSyncFileSuccessfully:(BOOL)success;

#pragma mark Helper Methods
/** Releases any existing `unappliedSyncChangesContext` and `unappliedSyncChangesCoreDataFactory` and sets new ones, linked to the set of sync changes specified in the given sync change set.
 
 @param aChangeSet The `TICDSSyncChangeSet` object specifying the set of changes to use.
 
 @return A managed object context to access the sync changes. */
- (NSManagedObjectContext *)contextForSyncChangesInUnappliedSyncChangeSet:(TICDSSyncChangeSet *)aChangeSet;

#pragma mark Configuration
/** Configure a background context (for applying sync changes) using the same persistent store coordinator as the main application context.
 
 @param aPersistentStoreCoordinator The persistent store coordinator to use for the background context. */
- (void)configureBackgroundApplicationContextForPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)aPersistentStoreCoordinator;

#pragma mark Properties
/** @name Properties */

/** A boolean indicating whether the operation is currently paused awaiting an instruction to continue, e.g. for conflict resolution. */
@property (assign, getter = isPaused) BOOL paused;

/** The resolution type for the most recent conflict, set before resuming the operation after a conflict is detected. */
@property (assign) TICDSSyncConflictResolutionType mostRecentConflictResolutionType;

/** An array of client identifiers for clients that synchronize with this document, excluding this client. */
@property (nonatomic, strong) NSArray *otherSynchronizedClientDeviceIdentifiers;

/** A dictionary of arrays; keys are client identifiers, values are sync change set identifiers for each of those clients. */
@property (strong) NSMutableDictionary *otherSynchronizedClientDeviceSyncChangeSetIdentifiers;

/** The sort descriptors used to sort sync change objects in a `SyncChangeSet` before being applied. */
@property (nonatomic, strong) NSArray *syncChangeSortDescriptors;

/** The warnings generated during this synchronization. */
@property (strong) NSMutableArray *synchronizationWarnings;

/** The integrity key provided either by the client to check existing data matches integrity, or set during registration for new documents. */
@property (strong) NSString *integrityKey;

/** @name File Locations */

/** The location of the `SyncChangesBeingSynchronized.syncchg` file for this synchronization operation. */
@property (strong) NSURL *localSyncChangesToMergeLocation;

/** The location of this document's `AppliedSyncChangeSets.ticdsync` file. */
@property (strong) NSURL *appliedSyncChangeSetsFileLocation;

/** The location of the `UnappliedSyncChanges` directory for this synchronization operation. */
@property (strong) NSURL *unappliedSyncChangesDirectoryLocation;

/** The location of this document's `UnappliedSyncChangeSets.ticdsync` file. */
@property (strong) NSURL *unappliedSyncChangeSetsFileLocation;

/** The location of the local RecentSync file to upload at the end of the synchronization process. */
@property (strong) NSURL *localRecentSyncFileLocation;

/** @name Managed Object Contexts and Factories */

/** A `TICoreDataFactory` to access the contents of the `AppliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, strong) TICoreDataFactory *appliedSyncChangeSetsCoreDataFactory;

/** The managed object context for the `AppliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, strong) NSManagedObjectContext *appliedSyncChangeSetsContext;

/** A `TICoreDataFactory` to access the contents of the `UnappliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, strong) TICoreDataFactory *unappliedSyncChangeSetsCoreDataFactory;

/** The managed object context for the `UnappliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, strong) NSManagedObjectContext *unappliedSyncChangeSetsContext;

/** A `TICoreDataFactory` to access the contents of a single, unapplied `SyncChangeSet` file. */
@property (nonatomic, strong) TICoreDataFactory *unappliedSyncChangesCoreDataFactory;

/** The managed object context for the changes in a single, unapplied `SyncChangeSet` file. */
@property (nonatomic, strong) NSManagedObjectContext *unappliedSyncChangesContext;

/** A `TICoreDataFactory` to access the contents of the local, unsynchronized set of `SyncChange`s. */
@property (nonatomic, strong) TICoreDataFactory *localSyncChangesToMergeCoreDataFactory;

/** The managed object context for the local, unsynchronized set of `SyncChange`s. */
@property (nonatomic, strong) NSManagedObjectContext *localSyncChangesToMergeContext;

/** The persistent store coordinator for the application - used to create a background application context, when needed. */
@property (strong) NSPersistentStoreCoordinator *primaryPersistentStoreCoordinator;

/** The managed object context (tied to the application's persistent store coordinator) in which `SyncChanges` are applied. */
@property (nonatomic, strong) TICDSSynchronizationOperationManagedObjectContext *backgroundApplicationContext;

#pragma mark Completion
/** @name Completion */

/** The total number of arrays of `SyncChangeSet` identifiers that need to be fetched. */
@property (nonatomic, assign) NSUInteger numberOfSyncChangeSetIDArraysToFetch;

/** The number of arrays of `SyncChangeSet` identifiers that have already been fetched. */
@property (nonatomic, assign) NSUInteger numberOfSyncChangeSetIDArraysFetched;

/** The number of arrays of `SyncChangeSet` identifiers that failed to fetch because of an error. */
@property (nonatomic, assign) NSUInteger numberOfSyncChangeSetIDArraysThatFailedToFetch;

/** The number of unapplied sync change sets that need to be fetched. */
@property (nonatomic, assign) NSUInteger numberOfUnappliedSyncChangeSetsToFetch;

/** The number of unapplied sync change sets that have already been fetched. */
@property (nonatomic, assign) NSUInteger numberOfUnappliedSyncChangeSetsFetched;

/** The number of unapplied sync change sets that failed to fetch because of an error. */
@property (nonatomic, assign) NSUInteger numberOfUnappliedSyncChangeSetsThatFailedToFetch;

@end
