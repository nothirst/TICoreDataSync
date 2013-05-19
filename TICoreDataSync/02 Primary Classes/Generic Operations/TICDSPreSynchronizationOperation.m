//
//  TICDSPreSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSPreSynchronizationOperation () <TICoreDataFactoryDelegate>

#pragma mark Properties
/** @name Properties */

/** An array of client identifiers for clients that synchronize with this document, excluding this client. */
@property (nonatomic, strong) NSArray *otherSynchronizedClientDeviceIdentifiers;

/** A dictionary of arrays; keys are client identifiers, values are sync change set identifiers for each of those clients. */
@property (strong) NSMutableDictionary *otherSynchronizedClientDeviceSyncChangeSetIdentifiers;

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

@implementation TICDSPreSynchronizationOperation

- (void)main
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    [self beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey];
}

#pragma mark - INTEGRITY KEY
- (void)beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Fetching remote integrity key");

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    [self fetchRemoteIntegrityKey];
}

- (void)fetchedRemoteIntegrityKey:(NSString *)aKey
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if (aKey == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch an integrity key: %@", [[self error] localizedDescription]);

        [self operationDidFailToComplete];
        return;
    }

    if (self.integrityKey && ![self.integrityKey isEqualToString:aKey]) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"The keys do not match: got %@, expecting %@", aKey, self.integrityKey);

        [self setError:[TICDSError errorWithCode:TICDSErrorCodeSynchronizationFailedBecauseIntegrityKeysDoNotMatch classAndMethod:__PRETTY_FUNCTION__]];

        [self operationDidFailToComplete];
        return;
    }

    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Integrity keys match, so continuing synchronization");
    [self beginFetchOfListOfClientDeviceIdentifiers];
}

#pragma mark Overridden Method
- (void)fetchRemoteIntegrityKey
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedRemoteIntegrityKey:nil];
}

#pragma mark - LIST OF DEVICE IDENTIFIERS
- (void)beginFetchOfListOfClientDeviceIdentifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fetch list of client device identifiers");

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    [self buildArrayOfClientDeviceIdentifiers];
}

- (void)builtArrayOfClientDeviceIdentifiers:(NSArray *)anArray
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if (anArray == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching list of client device identifiers");
        [self operationDidFailToComplete];
        return;
    }

    NSMutableArray *clientIdentifiers = [NSMutableArray arrayWithCapacity:[anArray count]];

    for ( NSString *eachClientIdentifier in anArray) {
        if ([eachClientIdentifier isEqualToString:[self clientIdentifier]]) {
            continue;
        }

        [clientIdentifiers addObject:eachClientIdentifier];
    }

    if ([clientIdentifiers count] < 1) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No other clients are synchronizing with this document, so finishing");
        [self operationDidCompleteSuccessfully];
        return;
    }

    self.otherSynchronizedClientDeviceIdentifiers = clientIdentifiers;

    [self beginFetchOfListOfSyncCommandSetIdentifiers];
}

#pragma mark Overridden Method
- (void)buildArrayOfClientDeviceIdentifiers
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self builtArrayOfClientDeviceIdentifiers:nil];
}

#pragma mark - LIST OF SYNC COMMAND SETS
- (void)beginFetchOfListOfSyncCommandSetIdentifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fetch list of SyncCommandSet identifiers for clients %@", self.otherSynchronizedClientDeviceIdentifiers);

    // TODO: Fetch of Sync Commands
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"***Not yet implemented*** so 'finished' fetch of local sync commands");

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    [self beginFetchOfListOfSyncChangeSetIdentifiers];
}

#pragma mark - LIST OF SYNC CHANGE SETS
- (void)beginFetchOfListOfSyncChangeSetIdentifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fetch list of SyncChangeSet identifiers");

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    self.numberOfSyncChangeSetIDArraysToFetch = [self.otherSynchronizedClientDeviceIdentifiers count];

    self.otherSynchronizedClientDeviceSyncChangeSetIdentifiers = [NSMutableDictionary dictionaryWithCapacity:[self.otherSynchronizedClientDeviceIdentifiers count]];

    for ( NSString *eachClientIdentifier in self.otherSynchronizedClientDeviceIdentifiers) {
        [self buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:eachClientIdentifier];
    }
}

- (void)builtArrayOfClientSyncChangeSetIdentifiers:(NSArray *)anArray forClientIdentifier:(NSString *)aClientIdentifier
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if (anArray == nil) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Failed to fetch an array of client sync change set identifiers for client identifier: %@", aClientIdentifier);
        [self increaseNumberOfSyncChangeSetIdentifierArraysThatFailedToFetch];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched an array of client sync change set identifiers");
        [self increaseNumberOfSyncChangeSetIdentifierArraysFetched];
        anArray = [self unappliedSyncChangeSetIdentifiersFromAvailableSyncChangeSetIdentifiers:anArray];
    }

    if ([anArray count] > 0) {
        [self.otherSynchronizedClientDeviceSyncChangeSetIdentifiers setValue:anArray forKey:aClientIdentifier];
    }

    if (self.numberOfSyncChangeSetIDArraysToFetch == self.numberOfSyncChangeSetIDArraysFetched) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finished fetching client sync change set IDs");

        [self beginFetchOfUnappliedSyncChanges];
    } else if (self.numberOfSyncChangeSetIDArraysToFetch == self.numberOfSyncChangeSetIDArraysFetched + self.numberOfSyncChangeSetIDArraysThatFailedToFetch) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"One or more sync change set IDs failed to fetch");
        [self operationDidFailToComplete];
    }
}

- (NSArray *)unappliedSyncChangeSetIdentifiersFromAvailableSyncChangeSetIdentifiers:(NSArray *)changeSetIdentifiers
{
    NSMutableArray *addedIdentifiers = [NSMutableArray array];

    for ( NSString *eachIdentifier in changeSetIdentifiers) {
        if ([self syncChangeSetHasBeenAppliedWithIdentifier:eachIdentifier]) {
            continue;
        }

        [addedIdentifiers addObject:eachIdentifier];
    }

    return addedIdentifiers;
}

- (BOOL)syncChangeSetHasBeenAppliedWithIdentifier:(NSString *)anIdentifier
{
    return [TICDSSyncChangeSet hasSyncChangeSetWithIdentifer:anIdentifier alreadyBeenAppliedInManagedObjectContext:self.appliedSyncChangeSetsContext];
}

#pragma mark Overridden Method
- (void)buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:(NSString *)anIdentifier
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self builtArrayOfClientSyncChangeSetIdentifiers:nil forClientIdentifier:anIdentifier];
}

#pragma mark - FETCH OF UNAPPLIED SYNC CHANGE SETS
- (void)beginFetchOfUnappliedSyncChanges
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Fetching unapplied sync change sets");

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if ([self.otherSynchronizedClientDeviceSyncChangeSetIdentifiers count] < 1) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No unapplied sync change sets to download and apply");

        [self operationDidCompleteSuccessfully];
        return;
    }

    NSString *unappliedSyncChangesPath = [self.unappliedSyncChangesDirectoryLocation path];

    for ( NSString *eachClientIdentifier in self.otherSynchronizedClientDeviceSyncChangeSetIdentifiers) {
        NSArray *syncChangeSets = [self.otherSynchronizedClientDeviceSyncChangeSetIdentifiers valueForKey:eachClientIdentifier];

        self.numberOfUnappliedSyncChangeSetsToFetch = self.numberOfUnappliedSyncChangeSetsToFetch + [syncChangeSets count];
    }

    NSString *fileLocation = nil;
    NSError *anyError = nil;
    for ( NSString *eachClientIdentifier in self.otherSynchronizedClientDeviceSyncChangeSetIdentifiers) {
        NSArray *syncChangeSets = [self.otherSynchronizedClientDeviceSyncChangeSetIdentifiers valueForKey:eachClientIdentifier];

        for ( NSString *eachSyncChangeSetIdentifier in syncChangeSets) {
            fileLocation = [unappliedSyncChangesPath stringByAppendingPathComponent:eachSyncChangeSetIdentifier];
            fileLocation = [fileLocation stringByAppendingPathExtension:TICDSSyncChangeSetFileExtension];

            if ([[self fileManager] fileExistsAtPath:fileLocation] && ![[self fileManager] removeItemAtPath:fileLocation error:&anyError]) {
                TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to remove existing downloaded but unapplied sync change set %@", eachSyncChangeSetIdentifier);
            }

            [self fetchSyncChangeSetWithIdentifier:eachSyncChangeSetIdentifier forClientIdentifier:eachClientIdentifier toLocation:[NSURL fileURLWithPath:fileLocation]];
        }
    }
}

- (void)fetchedSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientIdentifier:(NSString *)aClientIdentifier modificationDate:(NSDate *)aDate withSuccess:(BOOL)success
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if (success) {
        success = [self addUnappliedSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientWithIdentifier:aClientIdentifier modificationDate:aDate];
    }

    if (success) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched an unapplied sync change set");
        [self increaseNumberOfUnappliedSyncChangeSetsFetched];
    } else {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch an unapplied sync change set");
        [self increaseNumberOfUnappliedSyncChangeSetsThatFailedToFetch];
    }

    if (self.numberOfUnappliedSyncChangeSetsToFetch == self.numberOfUnappliedSyncChangeSetsFetched) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finished fetching unapplied sync change sets");
        NSError *anyError = nil;
        BOOL saveSuccess = [self.unappliedSyncChangeSetsContext save:&anyError];
        if (saveSuccess == NO) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save UnappliedSyncChanges.ticdsync file: %@", anyError);
        }
        
        [self operationDidCompleteSuccessfully];
    } else if (self.numberOfUnappliedSyncChangeSetsToFetch == self.numberOfUnappliedSyncChangeSetsFetched + self.numberOfUnappliedSyncChangeSetsThatFailedToFetch) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"One of more sync change sets failed to be fetched");
        [self operationDidFailToComplete];
    }
}

- (BOOL)addUnappliedSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientWithIdentifier:(NSString *)aClientIdentifier modificationDate:(NSDate *)aDate
{
    // Check whether it already exists
    NSError *anyError = nil;

    TICDSSyncChangeSet *unappliedSyncChangeSet = [TICDSSyncChangeSet ti_firstObjectMatchingPredicate:[NSPredicate predicateWithFormat:@"syncChangeSetIdentifier == %@", aChangeSetIdentifier] inManagedObjectContext:self.unappliedSyncChangeSetsContext error:&anyError];

    if (unappliedSyncChangeSet != nil) {
        return YES;
    }

    if (anyError) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataFetchError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to add unapplied sync change set to UnappliedSyncChangeSets.ticdsync: %@", anyError);
        return NO;
    }

    unappliedSyncChangeSet = [TICDSSyncChangeSet syncChangeSetWithIdentifier:aChangeSetIdentifier fromClient:aClientIdentifier creationDate:aDate inManagedObjectContext:self.unappliedSyncChangeSetsContext];

    if (unappliedSyncChangeSet == nil) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeObjectCreationError classAndMethod:__PRETTY_FUNCTION__]];
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to add unapplied sync change set to UnappliedSyncChangeSets.ticdsync.");
        return NO;
    }

    TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Added sync change set to UnappliedSyncChangeSets.ticdsync");

    return YES;
}

#pragma mark Overridden Method
- (void)fetchSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientIdentifier:(NSString *)aClientIdentifier toLocation:(NSURL *)aLocation
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientIdentifier:aClientIdentifier modificationDate:nil withSuccess:NO];
}

#pragma mark Overridden Method

- (void)increaseNumberOfSyncChangeSetIdentifierArraysToFetch
{
    self.numberOfSyncChangeSetIDArraysToFetch = self.numberOfSyncChangeSetIDArraysToFetch + 1;
}

- (void)increaseNumberOfSyncChangeSetIdentifierArraysFetched
{
    self.numberOfSyncChangeSetIDArraysFetched = self.numberOfSyncChangeSetIDArraysFetched + 1;
}

- (void)increaseNumberOfSyncChangeSetIdentifierArraysThatFailedToFetch
{
    self.numberOfSyncChangeSetIDArraysThatFailedToFetch = self.numberOfSyncChangeSetIDArraysThatFailedToFetch + 1;
}

- (void)increaseNumberOfUnappliedSyncChangeSetsToFetch
{
    self.numberOfUnappliedSyncChangeSetsToFetch = self.numberOfUnappliedSyncChangeSetsToFetch + 1;
}

- (void)increaseNumberOfUnappliedSyncChangeSetsFetched
{
    self.numberOfUnappliedSyncChangeSetsFetched = self.numberOfUnappliedSyncChangeSetsFetched + 1;
}

- (void)increaseNumberOfUnappliedSyncChangeSetsThatFailedToFetch
{
    self.numberOfUnappliedSyncChangeSetsThatFailedToFetch = self.numberOfUnappliedSyncChangeSetsThatFailedToFetch + 1;
}

#pragma mark - TICoreDataFactory Delegate
- (void)coreDataFactory:(TICoreDataFactory *)aFactory encounteredError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Applied Sync Change Sets Factory Error: %@", anError);
}

#pragma mark - Configuration

#pragma mark - Lazy Accessors

- (NSManagedObjectContext *)appliedSyncChangeSetsContext
{
    if (_appliedSyncChangeSetsContext) {
        return _appliedSyncChangeSetsContext;
    }

    _appliedSyncChangeSetsContext = [self.appliedSyncChangeSetsCoreDataFactory managedObjectContext];
    [_appliedSyncChangeSetsContext setUndoManager:nil];

    return _appliedSyncChangeSetsContext;
}

- (TICoreDataFactory *)appliedSyncChangeSetsCoreDataFactory
{
    if (_appliedSyncChangeSetsCoreDataFactory) {
        return _appliedSyncChangeSetsCoreDataFactory;
    }

    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _appliedSyncChangeSetsCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeSetDataModelName];
    [_appliedSyncChangeSetsCoreDataFactory setPersistentStoreType:TICDSSyncChangeSetsCoreDataPersistentStoreType];
    [_appliedSyncChangeSetsCoreDataFactory setPersistentStoreDataPath:[self.appliedSyncChangeSetsFileLocation path]];
    [_appliedSyncChangeSetsCoreDataFactory setDelegate:self];

    NSError *error = nil;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = _appliedSyncChangeSetsCoreDataFactory.persistentStoreCoordinator;
    for (TICDSSyncTransaction *syncTransaction in self.syncTransactions) {
        if ([self.fileManager fileExistsAtPath:[syncTransaction.unsavedAppliedSyncChangesFileURL path]]) {
            [persistentStoreCoordinator addPersistentStoreWithType:TICDSSyncChangeSetsCoreDataPersistentStoreType configuration:nil URL:syncTransaction.unsavedAppliedSyncChangesFileURL options:@{ NSReadOnlyPersistentStoreOption:@YES } error:&error];
        }
    }

    if (error != nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error attempting to add persistent stores to the appliedSyncChangeSets persistent store coordinator. Error: %@", error);
    }
    
    return _appliedSyncChangeSetsCoreDataFactory;
}

- (NSManagedObjectContext *)unappliedSyncChangeSetsContext
{
    if (_unappliedSyncChangeSetsContext) {
        return _unappliedSyncChangeSetsContext;
    }

    _unappliedSyncChangeSetsContext = [self.unappliedSyncChangeSetsCoreDataFactory managedObjectContext];
    [_unappliedSyncChangeSetsContext setUndoManager:nil];

    return _unappliedSyncChangeSetsContext;
}

- (TICoreDataFactory *)unappliedSyncChangeSetsCoreDataFactory
{
    if (_unappliedSyncChangeSetsCoreDataFactory) {
        return _unappliedSyncChangeSetsCoreDataFactory;
    }

    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _unappliedSyncChangeSetsCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeSetDataModelName];
    [_unappliedSyncChangeSetsCoreDataFactory setPersistentStoreType:TICDSSyncChangeSetsCoreDataPersistentStoreType];
    [_unappliedSyncChangeSetsCoreDataFactory setPersistentStoreDataPath:[self.unappliedSyncChangeSetsFileLocation path]];
    [_unappliedSyncChangeSetsCoreDataFactory setDelegate:self];
    
    return _unappliedSyncChangeSetsCoreDataFactory;
}

@end
