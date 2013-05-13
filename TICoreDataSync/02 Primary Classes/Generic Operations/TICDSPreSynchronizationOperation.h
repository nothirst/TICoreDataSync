//
//  TICDSPreSynchronizationOperation.h
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSOperation.h"

/** The `TICDSPreSynchronizationOperation` class describes a generic operation used by the `TICoreDataSync` framework to synchronize changes made to a document.
 
 In brief, a pre-synchronization operation pulls down remote sync commands and changes.
 
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
 
 Operations are typically created automatically by the relevant sync manager.
 
 @warning You must use one of the subclasses of `TICDSPreSynchronizationOperation`. */
@interface TICDSPreSynchronizationOperation : TICDSOperation

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

#pragma mark Properties
/** @name Properties */

/** The integrity key provided either by the client to check existing data matches integrity, or set during registration for new documents. */
@property (copy) NSString *integrityKey;

/** @name File Locations */

/** The location of this document's `UnappliedSyncChangeSets.ticdsync` file. */
@property (strong) NSURL *unappliedSyncChangeSetsFileLocation;

/** The location of the `UnappliedSyncChanges` directory for this synchronization operation. */
@property (strong) NSURL *unappliedSyncChangesDirectoryLocation;

/** The location of this document's `AppliedSyncChangeSets.ticdsync` file. */
@property (strong) NSURL *appliedSyncChangeSetsFileLocation;

/** The sync transactions whose unsaved applied sync change files will be used as persistent stores to augment the applied sync changes managed object context. */
@property NSArray *syncTransactions;

@end
