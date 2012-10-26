//
//  TICDSSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSSynchronizationOperation () <TICoreDataFactoryDelegate>

@property (nonatomic, copy) NSString *changeSetProgressString;
@property (nonatomic, readonly) NSNumberFormatter *uuidPrefixFormatter;

- (void)beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey;

- (void)beginFetchOfListOfClientDeviceIdentifiers;
- (void)beginFetchOfListOfSyncCommandSetIdentifiers;

- (void)increaseNumberOfSyncChangeSetIdentifierArraysToFetch;
- (void)increaseNumberOfSyncChangeSetIdentifierArraysFetched;
- (void)increaseNumberOfSyncChangeSetIdentifierArraysThatFailedToFetch;
- (void)beginFetchOfListOfSyncChangeSetIdentifiers;
- (NSArray *)unappliedSyncChangeSetIdentifiersFromAvailableSyncChangeSetIdentifiers:(NSArray *)changeSetIdentifiers;
- (BOOL)syncChangeSetHasBeenAppliedWithIdentifier:(NSString *)anIdentifier;

- (void)increaseNumberOfUnappliedSyncChangeSetsToFetch;
- (void)increaseNumberOfUnappliedSyncChangeSetsFetched;
- (void)increaseNumberOfUnappliedSyncChangeSetsThatFailedToFetch;
- (void)beginFetchOfUnappliedSyncChanges;

- (BOOL)addUnappliedSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientWithIdentifier:(NSString *)aClientIdentifier modificationDate:(NSDate *)aDate;

- (void)beginApplyingUnappliedSyncChangeSets;
- (BOOL)applyUnappliedSyncChangeSets:(NSArray *)syncChangeSets;
- (BOOL)addSyncChangeSetToAppliedSyncChangeSets:(TICDSSyncChangeSet *)aChangeSet;
- (BOOL)removeSyncChangeSetFileForSyncChangeSet:(TICDSSyncChangeSet *)aChangeSet;
- (void)continueAfterApplyingUnappliedSyncChangeSetsSuccessfully;
- (void)continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully;

- (BOOL)beginApplyingSyncChangesInChangeSet:(TICDSSyncChangeSet *)aChangeSet;
- (NSArray *)syncChangesAfterCheckingForConflicts:(NSArray *)syncChanges inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (NSArray *)remoteSyncChangesForObjectWithIdentifier:(NSString *)anIdentifier afterCheckingForConflictsInRemoteSyncChanges:(NSArray *)remoteSyncChanges inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
- (void)addWarningsForRemoteDeletionWithLocalChanges:(NSArray *)localChanges;
- (void)addWarningsForRemoteChangesWithLocalDeletion:(NSArray *)remoteChanges;
- (TICDSSyncConflictResolutionType)resolutionTypeForConflict:(TICDSSyncConflict *)aConflict;
- (void)applyObjectInsertedSyncChange:(TICDSSyncChange *)aSyncChange;
- (void)applyAttributeChangeSyncChange:(TICDSSyncChange *)aSyncChange;
- (void)applyObjectDeletedSyncChange:(TICDSSyncChange *)aSyncChange;
- (void)applyToOneRelationshipSyncChange:(TICDSSyncChange *)aSyncChange;
- (void)applyToManyRelationshipSyncChange:(TICDSSyncChange *)aSyncChange;

- (void)beginUploadOfLocalSyncCommands;
- (void)beginUploadOfLocalSyncChanges;
- (void)beginUploadOfRecentSyncFile;

@end

@implementation TICDSSynchronizationOperation

- (void)main
{
    [self beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey];
}

#pragma mark - INTEGRITY KEY
- (void)beginCheckWhetherRemoteIntegrityKeyMatchesLocalKey
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Fetching remote integrity key");

    [self fetchRemoteIntegrityKey];
}

- (void)fetchedRemoteIntegrityKey:(NSString *)aKey
{
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

    [self buildArrayOfClientDeviceIdentifiers];
}

- (void)builtArrayOfClientDeviceIdentifiers:(NSArray *)anArray
{
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
        TICDSLog(TICDSLogVerbosityEveryStep, @"No other clients are synchronizing with this document, so skipping to upload local sync commands");
        [self beginUploadOfLocalSyncCommands];
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

    [self beginFetchOfListOfSyncChangeSetIdentifiers];
}

#pragma mark - LIST OF SYNC CHANGE SETS
- (void)beginFetchOfListOfSyncChangeSetIdentifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fetch list of SyncChangeSet identifiers");

    self.numberOfSyncChangeSetIDArraysToFetch = [self.otherSynchronizedClientDeviceIdentifiers count];

    self.otherSynchronizedClientDeviceSyncChangeSetIdentifiers = [NSMutableDictionary dictionaryWithCapacity:[self.otherSynchronizedClientDeviceIdentifiers count]];

    for ( NSString *eachClientIdentifier in self.otherSynchronizedClientDeviceIdentifiers) {
        [self buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:eachClientIdentifier];
    }
}

- (void)builtArrayOfClientSyncChangeSetIdentifiers:(NSArray *)anArray forClientIdentifier:(NSString *)aClientIdentifier
{
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

    if ([self.otherSynchronizedClientDeviceSyncChangeSetIdentifiers count] < 1) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No unapplied sync change sets to download and apply");

        [self beginUploadOfLocalSyncCommands];
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
        [self beginApplyingUnappliedSyncChangeSets];
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

#pragma mark - APPLICATION OF UNAPPLIED SYNC CHANGE SETS

- (void)beginApplyingUnappliedSyncChangeSets
{
    if ([NSThread isMainThread]) {
        [self performSelectorInBackground:@selector(beginApplyingUnappliedSyncChangeSets) withObject:nil];
        return;
    }

    @autoreleasepool {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Checking how many sync change sets need to be applied");

        __block NSError *anyError = nil;
        NSArray *sortDescriptors = [NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:YES], [[NSSortDescriptor alloc] initWithKey:@"syncChangeSetIdentifier" ascending:YES], nil];

        NSArray *unappliedSyncChangeSets = [TICDSSyncChangeSet ti_allObjectsInManagedObjectContext:self.unappliedSyncChangeSetsContext sortedWithDescriptors:sortDescriptors error:&anyError];

        if (unappliedSyncChangeSets == nil) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataFetchError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
            return;
        }

        if ([unappliedSyncChangeSets count] < 1) {
            TICDSLog(TICDSLogVerbosityEveryStep, @"No other clients have uploaded any sync change sets, so proceeding to upload local sync commands");
            [self continueAfterApplyingUnappliedSyncChangeSetsSuccessfully];
            return;
        }

        self.synchronizationWarnings = [NSMutableArray arrayWithCapacity:20];

        BOOL shouldContinue = [self applyUnappliedSyncChangeSets:unappliedSyncChangeSets];

        if (shouldContinue) {
            anyError = nil;

            // Save Background Context (changes made to objects in application's context)
            __block BOOL success = NO;
            [self.backgroundApplicationContext performBlockAndWait:^{
                success = [self.backgroundApplicationContext save:&anyError];
            }];

            if (success == NO) {
                TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save background context: %@", anyError);
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
                return;
            }

            // Save UnsynchronizedSyncChanges context (UnsynchronizedSyncChanges.syncchg file)
            if (self.localSyncChangesToMergeContext && ![self.localSyncChangesToMergeContext save:&anyError]) {
                TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save unsynchroinzed sync changes context, after saving background context: %@", anyError);
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
                return;
            }

            // Save Applied Sync Change Sets context (AppliedSyncChangeSets.ticdsync file)
            success = [self.appliedSyncChangeSetsContext save:&anyError];
            if (success == NO) {
                TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save applied sync change sets context, after saving background context: %@", anyError);
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
                return;
            }

            // Save Unapplied Sync Change Sets context (UnappliedSYncChangeSets.ticdsync file)
            success = [self.unappliedSyncChangeSetsContext save:&anyError];
            if (success == NO) {
                TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save unapplied sync change sets context, after saving applied sync change sets context: %@", anyError);
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
                return;
            }

            [self continueAfterApplyingUnappliedSyncChangeSetsSuccessfully];
        } else {
            [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
        }
    }
}

- (BOOL)applyUnappliedSyncChangeSets:(NSArray *)unappliedSyncChangeSets
{
    BOOL shouldContinue = YES;

    NSInteger changeSetCount = 1;
    for ( TICDSSyncChangeSet *unappliedSyncChangeSet in unappliedSyncChangeSets) {
        self.changeSetProgressString = [NSString stringWithFormat:@"Change set %ld of %lu", (long)changeSetCount++, (unsigned long)[unappliedSyncChangeSets count]];
        shouldContinue = [self beginApplyingSyncChangesInChangeSet:unappliedSyncChangeSet];
        if (shouldContinue == NO) {
            break;
        }

        shouldContinue = [self addSyncChangeSetToAppliedSyncChangeSets:unappliedSyncChangeSet];
        if (shouldContinue == NO) {
            break;
        }

        shouldContinue = [self removeSyncChangeSetFileForSyncChangeSet:unappliedSyncChangeSet];
        if (shouldContinue == NO) {
            break;
        }

        // Finally, remove the change set from the UnappliedSyncChangeSets context;
            [self.unappliedSyncChangeSetsContext deleteObject:unappliedSyncChangeSet];
    }

    return shouldContinue;
}

- (BOOL)addSyncChangeSetToAppliedSyncChangeSets:(TICDSSyncChangeSet *)previouslyUnappliedSyncChangeSet
{
    NSString *syncChangeSetIdentifier = nil;
    NSString *clientIdentifier = nil;
    NSDate *creationDate = nil;
    
        syncChangeSetIdentifier = previouslyUnappliedSyncChangeSet.syncChangeSetIdentifier;
        clientIdentifier = previouslyUnappliedSyncChangeSet.clientIdentifier;
        creationDate = previouslyUnappliedSyncChangeSet.creationDate;
    
    TICDSSyncChangeSet *appliedSyncChangeSet = [TICDSSyncChangeSet changeSetWithIdentifier:syncChangeSetIdentifier inManagedObjectContext:self.appliedSyncChangeSetsContext];

    if (appliedSyncChangeSet == nil) {
        appliedSyncChangeSet = [TICDSSyncChangeSet syncChangeSetWithIdentifier:syncChangeSetIdentifier fromClient:clientIdentifier creationDate:creationDate inManagedObjectContext:self.appliedSyncChangeSetsContext];
    }

    if (appliedSyncChangeSet == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Unable to create sync change set in applied sync change sets context");
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeObjectCreationError classAndMethod:__PRETTY_FUNCTION__]];
        return NO;
    }

        [appliedSyncChangeSet setLocalDateOfApplication:[NSDate date]];

    return YES;
}

- (BOOL)removeSyncChangeSetFileForSyncChangeSet:(TICDSSyncChangeSet *)syncChangeSet
{
    NSString *pathToSyncChangeSetFile = [self.unappliedSyncChangesDirectoryLocation path];
    pathToSyncChangeSetFile = [pathToSyncChangeSetFile stringByAppendingPathComponent:[syncChangeSet fileName]];

    if ([[self fileManager] fileExistsAtPath:pathToSyncChangeSetFile] == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Sync change set just applied no longer seems to exist on disc, which is strange, but not fatal, so continuing");
        return YES;
    }

    NSError *anyError = nil;
    BOOL success = [[self fileManager] removeItemAtPath:pathToSyncChangeSetFile error:&anyError];

    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete sync change set file from disc; not fatal, so continuing: %@", anyError);
        return YES;
    }

    return YES;
}

- (void)continueAfterApplyingUnappliedSyncChangeSetsSuccessfully
{
    if ([self needsMainThread] && ![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(continueAfterApplyingUnappliedSyncChangeSetsSuccessfully) withObject:nil waitUntilDone:NO];
        return;
    }

    [self beginUploadOfLocalSyncCommands];
}

- (void)continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully
{
    if ([self needsMainThread] && ![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully) withObject:nil waitUntilDone:NO];
        return;
    }

    [self operationDidFailToComplete];
}

#pragma mark - APPLYING EACH CHANGE SET

- (BOOL)beginApplyingSyncChangesInChangeSet:(TICDSSyncChangeSet *)unappliedSyncChangeSet
{
    NSString *syncChangeSetIdentifier = [unappliedSyncChangeSet syncChangeSetIdentifier];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying change set %@", syncChangeSetIdentifier);
    
    NSManagedObjectContext *unappliedSyncChangesContext = [self contextForSyncChangesInUnappliedSyncChangeSet:unappliedSyncChangeSet];
    
    NSError *anyError = nil;
    __block NSArray *unappliedSyncChanges = [TICDSSyncChange ti_allObjectsInManagedObjectContext:unappliedSyncChangesContext sortedWithDescriptors:self.syncChangeSortDescriptors error:&anyError];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"There are %lu changes in this set", (unsigned long)[unappliedSyncChanges count]);
    
    unappliedSyncChanges = [self syncChangesAfterCheckingForConflicts:unappliedSyncChanges inManagedObjectContext:unappliedSyncChangesContext];
    
        NSSortDescriptor *sequenceSort = [[NSSortDescriptor alloc] initWithKey:@"changeType" ascending:YES];
        unappliedSyncChanges = [unappliedSyncChanges sortedArrayUsingDescriptors:[NSArray arrayWithObject:sequenceSort]];
        
        NSInteger changeCount = 1;
        // Apply each object's changes in turn
        for ( TICDSSyncChange *eachChange in unappliedSyncChanges) {
            switch ( [[eachChange changeType] unsignedIntegerValue]) {
                case TICDSSyncChangeTypeObjectInserted: {
                    [self applyObjectInsertedSyncChange:eachChange];
                    [self.backgroundApplicationContext performBlockAndWait:^{
                        [self.backgroundApplicationContext processPendingChanges];
                    }];
                    break;
                }
                case TICDSSyncChangeTypeAttributeChanged: {
                    [self applyAttributeChangeSyncChange:eachChange];
                    break;
                }
                case TICDSSyncChangeTypeToOneRelationshipChanged: {
                    [self applyToOneRelationshipSyncChange:eachChange];
                    break;
                }
                case TICDSSyncChangeTypeToManyRelationshipChangedByAddingObject:
                case TICDSSyncChangeTypeToManyRelationshipChangedByRemovingObject: {
                    [self applyToManyRelationshipSyncChange:eachChange];
                    break;
                }
                case TICDSSyncChangeTypeObjectDeleted: {
                    [self applyObjectDeletedSyncChange:eachChange];
                    break;
                }
            }
            
            changeCount++;
            if ([self ti_delegateRespondsToSelector:@selector(synchronizationOperation:processedChangeNumber:outOfTotalChangeCount:fromClientNamed:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [(id)self.delegate synchronizationOperation:self processedChangeNumber:[NSNumber numberWithInteger:changeCount] outOfTotalChangeCount:[NSNumber numberWithInteger:[unappliedSyncChanges count]] fromClientNamed:self.changeSetProgressString];
                });
            }
        }
    
    [self.backgroundApplicationContext performBlockAndWait:^{
        [self.backgroundApplicationContext processPendingChanges];
    }];
    
    return YES;
}

- (NSManagedObjectContext *)contextForSyncChangesInUnappliedSyncChangeSet:(TICDSSyncChangeSet *)unappliedSyncChangeSet
{
    NSString *fileName = [unappliedSyncChangeSet fileName];
    
    self.unappliedSyncChangesContext = nil;
    self.unappliedSyncChangesCoreDataFactory = nil;

    TICoreDataFactory *factory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeDataModelName];
    [factory setDelegate:self];
    [factory setPersistentStoreType:TICDSSyncChangesCoreDataPersistentStoreType];
    [factory setPersistentStoreDataPath:[[self.unappliedSyncChangesDirectoryLocation path] stringByAppendingPathComponent:fileName]];

    self.unappliedSyncChangesCoreDataFactory = factory;

    self.unappliedSyncChangesContext = [factory managedObjectContext];

    return self.unappliedSyncChangesContext;
}

#pragma mark Conflicts
- (NSArray *)syncChangesAfterCheckingForConflicts:(NSArray *)syncChanges inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSArray *identifiersOfAffectedObjects = [syncChanges valueForKeyPath:@"@distinctUnionOfObjects.objectSyncID"];
        TICDSLog(TICDSLogVerbosityEveryStep, @"Affected Object identifiers: %@", [identifiersOfAffectedObjects componentsJoinedByString:@", "]);
    
    if (self.localSyncChangesToMergeContext == nil) {
        return syncChanges;
    }
    
    NSMutableArray *syncChangesToReturn = [NSMutableArray arrayWithCapacity:[syncChanges count]];
    
        NSArray *syncChangesForEachObject = nil;
        for (NSString *eachIdentifier in identifiersOfAffectedObjects) {
            syncChangesForEachObject = [syncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"objectSyncID == %@", eachIdentifier]];
            
            syncChangesForEachObject = [self remoteSyncChangesForObjectWithIdentifier:eachIdentifier afterCheckingForConflictsInRemoteSyncChanges:syncChangesForEachObject inManagedObjectContext:managedObjectContext];
            [syncChangesToReturn addObjectsFromArray:syncChangesForEachObject];
        }
    
    return syncChangesToReturn;
}

- (NSArray *)remoteSyncChangesForObjectWithIdentifier:(NSString *)anIdentifier afterCheckingForConflictsInRemoteSyncChanges:(NSArray *)remoteSyncChanges inManagedObjectContext:(NSManagedObjectContext *)remoteSyncChangesManagedObjectContext
{
    NSError *anyError = nil;
    NSArray *localSyncChanges = [TICDSSyncChange ti_objectsMatchingPredicate:[NSPredicate predicateWithFormat:@"objectSyncID == %@", anIdentifier] inManagedObjectContext:self.localSyncChangesToMergeContext sortedByKey:@"changeType" ascending:YES error:&anyError];
    
    // Used to trigger faults on all objects if debugging
    /*    NSArray *allSyncChanges = [TICDSSyncChange ti_allObjectsInManagedObjectContext:self.localSyncChangesToMergeContext error:&anyError];
     for( TICDSSyncChange *eachChange in allSyncChanges) {
     NSString *something = [eachChange objectEntityName];
     something = [eachChange relatedObjectEntityName];
     }
     */
    if (localSyncChanges == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch local sync changes while checking for conflicts: %@", anyError);
        return remoteSyncChanges;
    }
    
    if ([localSyncChanges count] < 1) {
        // No matching local sync changes, so all remote changes can be processed
        return remoteSyncChanges;
    }
    
    NSMutableArray *remoteSyncChangesToReturn = [NSMutableArray arrayWithArray:remoteSyncChanges];
    
    // Check if remote has deleted an object that has been changed locally
    NSArray *deletionChanges = [remoteSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeObjectDeleted]];
    
    if ([deletionChanges count] > 0) {
            // remote has deleted an object, so add warnings for all local changes
            [self addWarningsForRemoteDeletionWithLocalChanges:localSyncChanges];
            
            // Delete all local sync changes for this object
            for ( TICDSSyncChange *eachLocalChange in localSyncChanges) {
                [self.localSyncChangesToMergeContext deleteObject:eachLocalChange];
            }
    }
    
    // Check if remote has changed attributes on an object that has been deleted locally
    NSArray *changeChanges = [remoteSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeAttributeChanged]];
    
    deletionChanges = [localSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeObjectDeleted]];
    
    if ([changeChanges count] > 0 && [deletionChanges count] > 0) {
            // remote has changed an object, so add warnings for each of the changes
            [self addWarningsForRemoteChangesWithLocalDeletion:changeChanges];
            
            // Remove change sync changs from remoteSyncChanges
            [remoteSyncChangesToReturn removeObjectsInArray:changeChanges];
    }
    
    NSString *const objectID = @"objectID";
    NSString *const relevantKey = @"relevantKey";
    NSString *const changedAttributes = @"changedAttributes";
    NSString *const objectEntityName = @"objectEntityName";
    NSString *const objectSyncID = @"objectSyncID";
    
    NSMutableArray *remoteChangeDictionaries = [[NSMutableArray alloc] init];;
        NSArray *remoteAttributeChanges = [remoteSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeAttributeChanged]];
        for ( TICDSSyncChange *eachRemoteChange in remoteAttributeChanges) {
            [remoteChangeDictionaries addObject:@{ objectID : eachRemoteChange.objectID,
                                  objectSyncID : eachRemoteChange.objectSyncID,
                              objectEntityName : eachRemoteChange.objectEntityName,
                                   relevantKey : eachRemoteChange.relevantKey,
                             changedAttributes : eachRemoteChange.changedAttributes }];
        }
    
    NSMutableArray *localChangeDictionaries = [[NSMutableArray alloc] init];
        NSArray *localAttributeChanges = [localSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeAttributeChanged]];
        for (TICDSSyncChange *eachLocalChange in localAttributeChanges) {
            [localChangeDictionaries addObject:@{ objectID : eachLocalChange.objectID,
                                 objectSyncID : eachLocalChange.objectSyncID,
                             objectEntityName : eachLocalChange.objectEntityName,
                                  relevantKey : eachLocalChange.relevantKey,
                            changedAttributes : eachLocalChange.changedAttributes }];
        }
    
    // Check if remote has changed an object's attribute and local has changed the same object attribute
    for ( NSDictionary *eachRemoteChangeDictionary in remoteChangeDictionaries) {
        // check the attribute name against each local attribute name
        for ( NSDictionary *eachLocalChangeDictionary in localChangeDictionaries) {
            if ([eachLocalChangeDictionary[relevantKey] isEqualToString:eachRemoteChangeDictionary[relevantKey]] == NO) {
                continue;
            }
            
            if ([eachLocalChangeDictionary[changedAttributes] isEqual:eachRemoteChangeDictionary[changedAttributes]]) {
                // both changes changed the value to the same thing so remove the local, unpushed sync change
                    TICDSSyncChange *localChange = (TICDSSyncChange *)[self.localSyncChangesToMergeContext objectWithID:eachLocalChangeDictionary[objectID]];
                    [self.localSyncChangesToMergeContext deleteObject:localChange];
                continue;
            }
            
            // if we get here, we have a conflict between eachRemoteChange and eachLocalChange
            TICDSSyncConflict *conflict = [TICDSSyncConflict syncConflictOfType:TICDSSyncConflictRemoteAttributeChangedAndLocalAttributeChanged forEntityName:eachLocalChangeDictionary[objectEntityName] key:eachLocalChangeDictionary[relevantKey] objectSyncID:eachLocalChangeDictionary[objectSyncID]];
            [conflict setLocalInformation:[NSDictionary dictionaryWithObject:eachLocalChangeDictionary[changedAttributes] forKey:kTICDSChangedAttributeValue]];
            [conflict setRemoteInformation:[NSDictionary dictionaryWithObject:eachRemoteChangeDictionary[changedAttributes] forKey:kTICDSChangedAttributeValue]];
            TICDSSyncConflictResolutionType resolutionType = [self resolutionTypeForConflict:conflict];
            
            if ([self isCancelled]) {
                [self operationWasCancelled];
                return nil;
            }
            
            if (resolutionType == TICDSSyncConflictResolutionTypeRemoteWins) {
                // just delete the local sync change so the remote change wins
                    TICDSSyncChange *localChange = (TICDSSyncChange *)[self.localSyncChangesToMergeContext objectWithID:eachLocalChangeDictionary[objectID]];
                    [self.localSyncChangesToMergeContext deleteObject:localChange];
            } else if (resolutionType == TICDSSyncConflictResolutionTypeLocalWins) {
                // remove the remote sync change so it's not applied
                    TICDSSyncChange *remoteChange = (TICDSSyncChange *)[remoteSyncChangesManagedObjectContext objectWithID:eachRemoteChangeDictionary[objectID]];
                    [remoteSyncChangesToReturn removeObject:remoteChange];
            }
        }
    }
    
    return remoteSyncChangesToReturn;
}

- (void)addWarningsForRemoteDeletionWithLocalChanges:(NSArray *)localChanges
{
    for ( TICDSSyncChange *eachLocalChange in localChanges) {
        switch ( [[eachLocalChange changeType] unsignedIntegerValue]) {
            case TICDSSyncChangeTypeAttributeChanged:
                [self.synchronizationWarnings addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectWithAttributesChangedLocallyAlreadyDeletedByRemoteSyncChange entityName:[eachLocalChange objectEntityName] relatedObjectEntityName:nil attributes:[eachLocalChange changedAttributes]]];
                break;
        }
    }
}

- (void)addWarningsForRemoteChangesWithLocalDeletion:(NSArray *)remoteChanges
{
    for ( TICDSSyncChange *eachRemoteChange in remoteChanges) {
        switch ( [[eachRemoteChange changeType] unsignedIntegerValue]) {
            case TICDSSyncChangeTypeAttributeChanged:
                [self.synchronizationWarnings addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectWithAttributesChangedRemotelyNowDeletedByLocalSyncChange entityName:[eachRemoteChange objectEntityName] relatedObjectEntityName:nil attributes:[eachRemoteChange changedAttributes]]];
                break;

            case TICDSSyncChangeTypeToOneRelationshipChanged:
            case TICDSSyncChangeTypeToManyRelationshipChangedByAddingObject:
            case TICDSSyncChangeTypeToManyRelationshipChangedByRemovingObject:
                [self.synchronizationWarnings addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectWithRelationshipsChangedRemotelyNowDeletedByLocalSyncChange entityName:[eachRemoteChange objectEntityName] relatedObjectEntityName:[eachRemoteChange relatedObjectEntityName] attributes:nil]];
                break;
        }
    }
}

- (TICDSSyncConflictResolutionType)resolutionTypeForConflict:(TICDSSyncConflict *)aConflict
{
    self.paused = YES;

    if ([self ti_delegateRespondsToSelector:@selector(synchronizationOperation:pausedToDetermineResolutionOfConflict:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
             [(id)self.delegate synchronizationOperation:self pausedToDetermineResolutionOfConflict:aConflict];
         }];
    }

    while ( [self isPaused] && ![self isCancelled]) {
        [NSThread sleepForTimeInterval:0.2];
    }

    if ([self ti_delegateRespondsToSelector:@selector(synchronizationOperationResumedFollowingResolutionOfConflict:)]) {
        [self runOnMainQueueWithoutDeadlocking:^{
             [(id)self.delegate synchronizationOperationResumedFollowingResolutionOfConflict:self];
         }];
    }

    return self.mostRecentConflictResolutionType;
}

#pragma mark Fetching Affected Objects

/**
 This method always needs to be scoped within the confines of a call to performBlock: or performBlockAndWait: on the backgroundApplicationContext.
 */
- (NSManagedObject *)backgroundApplicationContextObjectForEntityName:(NSString *)entityName syncIdentifier:(NSString *)aSyncIdentifier
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:self.backgroundApplicationContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", TICDSSyncIDAttributeName, aSyncIdentifier]];

    NSError *anyError = nil;
    NSArray *results = [self.backgroundApplicationContext executeFetchRequest:fetchRequest error:&anyError];
    if (results == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching affected object: %@", anyError);
    }

    return [results lastObject];
}

#pragma mark Applying Changes

- (void)applyObjectInsertedSyncChange:(TICDSSyncChange *)syncChange
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Insertion sync change");

    NSString *entityName = syncChange.objectEntityName;
    NSString *ticdsSyncID = syncChange.objectSyncID;
    id changedAttributes = [syncChange changedAttributes];
    NSArray *changedAttributeKeys = [[syncChange changedAttributes] allKeys];

    TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"[%@] %@", syncChange, entityName);

    [self.backgroundApplicationContext performBlockAndWait:^{
        NSManagedObject *insertedObject = nil;
        
        // Check to see if the object already exists before inserting it.
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:self.backgroundApplicationContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", TICDSSyncIDAttributeName, ticdsSyncID]];
        
        NSError *anyError = nil;
        NSArray *results = [self.backgroundApplicationContext executeFetchRequest:fetchRequest error:&anyError];
        if ([results count] == 0) {
            insertedObject = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:self.backgroundApplicationContext];
            TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Inserted object: %@", insertedObject);
        } else {
            insertedObject = [results lastObject];
            TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Attempted to insert an object that already existed, updating existing object instead.: %@", insertedObject);
        }
        
        for (id key in changedAttributeKeys) {
            [insertedObject willChangeValueForKey:key];
            [insertedObject setPrimitiveValue:[changedAttributes valueForKey:key] forKey:key];
            [insertedObject didChangeValueForKey:key];
        }
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Updated object: %@", insertedObject);
    }];
}

- (void)applyAttributeChangeSyncChange:(TICDSSyncChange *)syncChange
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Attribute Change sync change");
    
    NSString *objectEntityName = syncChange.objectEntityName;
    NSString *objectSyncID = syncChange.objectSyncID;
    id changedAttributes = syncChange.changedAttributes;
    NSString *relevantKey = syncChange.relevantKey;
    
    [self.backgroundApplicationContext performBlockAndWait:^{
        NSManagedObject *object = [self backgroundApplicationContextObjectForEntityName:objectEntityName syncIdentifier:objectSyncID];
        
        if (object == nil) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object not found locally for attribute change to %@", objectEntityName);
            [self.synchronizationWarnings addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteAttributeSyncChange entityName:objectEntityName relatedObjectEntityName:nil attributes:changedAttributes]];
            return;
        }
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"%@", objectEntityName);
        
        [object willChangeValueForKey:relevantKey];
        [object setPrimitiveValue:changedAttributes forKey:relevantKey];
        [object didChangeValueForKey:relevantKey];
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Changed attribute on object: %@", object);
    }];
}

- (void)applyToOneRelationshipSyncChange:(TICDSSyncChange *)syncChange
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Relationship Change sync change");
    
    NSString *objectEntityName = syncChange.objectEntityName;
    NSString *objectSyncID = syncChange.objectSyncID;
    id changedAttributes = syncChange.changedAttributes;
    NSString *relevantKey = syncChange.relevantKey;
    NSString *relatedObjectEntityName = syncChange.relatedObjectEntityName;
    id changedRelationships = syncChange.changedRelationships;
    
    [self.backgroundApplicationContext performBlockAndWait:^{
        NSManagedObject *object = [self backgroundApplicationContextObjectForEntityName:objectEntityName syncIdentifier:objectSyncID];
        
        if (object == nil) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object not found locally for attribute change %@", objectEntityName);
            [self.synchronizationWarnings addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteRelationshipSyncChange entityName:objectEntityName relatedObjectEntityName:relatedObjectEntityName attributes:changedAttributes]];
            return;
        }
        
        NSManagedObject *relatedObject = [self backgroundApplicationContextObjectForEntityName:relatedObjectEntityName syncIdentifier:changedRelationships];
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"%@", objectEntityName);
        [object willChangeValueForKey:relevantKey];
        [object setPrimitiveValue:relatedObject forKey:relevantKey];
        [object didChangeValueForKey:relevantKey];
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Changed to-one relationship on object: %@", object);
    }];
}

- (void)applyToManyRelationshipSyncChange:(TICDSSyncChange *)syncChange
{
    NSString *objectEntityName = syncChange.objectEntityName;
    NSString *objectSyncID = syncChange.objectSyncID;
    id changedAttributes = syncChange.changedAttributes;
    NSString *relevantKey = syncChange.relevantKey;
    NSString *relatedObjectEntityName = syncChange.relatedObjectEntityName;
    id changedRelationships = syncChange.changedRelationships;
    NSNumber *changeType = syncChange.changeType;
    
    [self.backgroundApplicationContext performBlockAndWait:^{
        NSManagedObject *object = [self backgroundApplicationContextObjectForEntityName:objectEntityName syncIdentifier:objectSyncID];
        
        if (object == nil) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object not found locally for attribute change %@", objectEntityName);
            [self.synchronizationWarnings addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteRelationshipSyncChange entityName:objectEntityName relatedObjectEntityName:relatedObjectEntityName attributes:changedAttributes]];
            return;
        }
        
        // capitalize the first char of relationship name to change e.g., someObjects into SomeObjects
        NSString *relationshipName = [relevantKey substringToIndex:1];
        relationshipName = [relationshipName capitalizedString];
        relationshipName = [relationshipName stringByAppendingString:[relevantKey substringFromIndex:1]];
        
        NSString *selectorName = nil;
        
        if ([changeType unsignedIntegerValue] == TICDSSyncChangeTypeToManyRelationshipChangedByAddingObject) {
            selectorName = [NSString stringWithFormat:@"add%@Object:", relationshipName];
        } else {
            selectorName = [NSString stringWithFormat:@"remove%@Object:", relationshipName];
        }
        
        NSManagedObject *relatedObject = [self backgroundApplicationContextObjectForEntityName:relatedObjectEntityName syncIdentifier:changedRelationships];
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [object performSelector:NSSelectorFromString(selectorName) withObject:relatedObject];
#pragma clang diagnostic pop
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"%@", objectEntityName);
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Changed to-many relationships on object: %@", object);
    }];
}

- (void)applyObjectDeletedSyncChange:(TICDSSyncChange *)syncChange
{
    NSString *objectEntityName = syncChange.objectEntityName;
    NSString *objectSyncID = syncChange.objectSyncID;
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Deletion sync change");

    [self.backgroundApplicationContext performBlockAndWait:^{
        NSManagedObject *object = [self backgroundApplicationContextObjectForEntityName:objectEntityName syncIdentifier:objectSyncID];
        
        if (object == nil) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object not found locally for deletion sync change %@", objectEntityName);
            [self.synchronizationWarnings addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteDeletionSyncChange entityName:objectEntityName relatedObjectEntityName:nil attributes:nil]];
            return;
        }
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"%@", objectEntityName);
        
        [self.backgroundApplicationContext deleteObject:object];
    }];
}

#pragma mark - UPLOAD OF LOCAL SYNC COMMANDS
- (void)beginUploadOfLocalSyncCommands
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to upload local sync commands");

    // TODO: Upload of Local Sync Commands
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"***Not yet implemented*** so 'finished' local sync commands");

    [self beginUploadOfLocalSyncChanges];
}

#pragma mark - UPLOAD OF LOCAL SYNC CHANGES

- (void)beginUploadOfLocalSyncChanges
{
    if ([[self fileManager] fileExistsAtPath:[self.localSyncChangesToMergeLocation path]] == NO) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No local sync changes file to push on this sync");
        [self beginUploadOfRecentSyncFile];
        return;
    }

    TICDSLog(TICDSLogVerbosityEveryStep, @"Renaming sync changes file ready for upload");

    NSString *identifier = [NSString stringWithFormat:@"%@-%@", [self.uuidPrefixFormatter stringFromNumber:[NSNumber numberWithDouble:CFAbsoluteTimeGetCurrent()]], [TICDSUtilities uuidString]];

    NSString *filePath = [self.localSyncChangesToMergeLocation path];
    filePath = [filePath stringByDeletingLastPathComponent];
    filePath = [filePath stringByAppendingPathComponent:identifier];
    filePath = [filePath stringByAppendingPathExtension:TICDSSyncChangeSetFileExtension];

    NSError *anyError = nil;
    BOOL success = [[self fileManager] moveItemAtPath:[self.localSyncChangesToMergeLocation path] toPath:filePath error:&anyError];

    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to move local sync changes to merge file");

        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self operationDidFailToComplete];
        return;
    }

    NSDate *date = [NSDate date];

    TICDSLog(TICDSLogVerbosityEveryStep, @"Adding local sync change set into AppliedSyncChanges");
    TICDSSyncChangeSet *appliedSyncChangeSet = [TICDSSyncChangeSet syncChangeSetWithIdentifier:identifier fromClient:[self clientIdentifier] creationDate:date inManagedObjectContext:self.appliedSyncChangeSetsContext];

    if (appliedSyncChangeSet == nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Unable to create sync change set in applied sync change sets context");
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeObjectCreationError classAndMethod:__PRETTY_FUNCTION__]];
        [self operationDidFailToComplete];
        return;
    }

    [appliedSyncChangeSet setLocalDateOfApplication:date];

    // Save Applied Sync Change Sets context (AppliedSyncChangeSets.ticdsync file)
    success = [self.appliedSyncChangeSetsContext save:&anyError];
    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save applied sync change sets context, after adding local merged changes: %@", anyError);
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self operationDidFailToComplete];
        return;
    }

    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to upload local sync changes");
    [self uploadLocalSyncChangeSetFileAtLocation:[NSURL fileURLWithPath:filePath]];
}

- (void)uploadedLocalSyncChangeSetFileSuccessfully:(BOOL)success
{
    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload local sync changes files");
        [self operationDidFailToComplete];
        return;
    }

    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Uploaded local sync changes file");

    [self beginUploadOfRecentSyncFile];
}

#pragma mark Overridden Method
- (void)uploadLocalSyncChangeSetFileAtLocation:(NSURL *)aLocation
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self uploadedLocalSyncChangeSetFileSuccessfully:NO];
}

#pragma mark - RECENT SYNC FILE
- (void)beginUploadOfRecentSyncFile
{
    NSString *recentSyncFilePath = [self.localRecentSyncFileLocation path];

    NSDictionary *recentSyncDictionary = [NSDictionary dictionaryWithObject:[NSDate date] forKey:kTICDSLastSyncDate];

    BOOL success = [recentSyncDictionary writeToFile:recentSyncFilePath atomically:YES];

    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to write RecentSync file to helper file location, but not absolutely fatal so continuing");
        [self operationDidCompleteSuccessfully];
        return;
    }

    [self uploadRecentSyncFileAtLocation:[NSURL fileURLWithPath:recentSyncFilePath]];
}

- (void)uploadedRecentSyncFileSuccessfully:(BOOL)success
{
    if (success == NO) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload RecentSync file, but not absolutely fatal so continuing: %@", [self error]);
    }

    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)uploadRecentSyncFileAtLocation:(NSURL *)aLocation
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self uploadedRecentSyncFileSuccessfully:NO];
}

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
- (void)configureBackgroundApplicationContextForPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)aPersistentStoreCoordinator
{
    self.primaryPersistentStoreCoordinator = aPersistentStoreCoordinator;
}

#pragma mark - Initialization and Deallocation
- (id)initWithDelegate:(NSObject<TICDSSynchronizationOperationDelegate> *)aDelegate
{
    return [super initWithDelegate:aDelegate];
}

- (void)dealloc
{
    _otherSynchronizedClientDeviceIdentifiers = nil;
    _otherSynchronizedClientDeviceSyncChangeSetIdentifiers = nil;
    _syncChangeSortDescriptors = nil;
    _synchronizationWarnings = nil;

    _localSyncChangesToMergeLocation = nil;
    _appliedSyncChangeSetsFileLocation = nil;
    _unappliedSyncChangesDirectoryLocation = nil;
    _unappliedSyncChangeSetsFileLocation = nil;
    _localRecentSyncFileLocation = nil;

    _appliedSyncChangeSetsCoreDataFactory = nil;
    _appliedSyncChangeSetsContext = nil;
    _unappliedSyncChangeSetsCoreDataFactory = nil;
    _unappliedSyncChangeSetsContext = nil;
    _unappliedSyncChangesCoreDataFactory = nil;
    _unappliedSyncChangesContext = nil;
    _localSyncChangesToMergeCoreDataFactory = nil;
    _localSyncChangesToMergeContext = nil;
    _primaryPersistentStoreCoordinator = nil;
    _backgroundApplicationContext = nil;
}

#pragma mark - Lazy Accessors
- (NSArray *)syncChangeSortDescriptors
{
    if (_syncChangeSortDescriptors) {
        return _syncChangeSortDescriptors;
    }

    _syncChangeSortDescriptors = [[NSArray alloc] initWithObjects:
                                  [[NSSortDescriptor alloc] initWithKey:@"changeType" ascending:YES],
                                  [[NSSortDescriptor alloc] initWithKey:@"localTimeStamp" ascending:YES],
                                  nil];

    return _syncChangeSortDescriptors;
}

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

- (NSManagedObjectContext *)localSyncChangesToMergeContext
{
    if (_localSyncChangesToMergeContext) {
        return _localSyncChangesToMergeContext;
    }

    _localSyncChangesToMergeContext = [self.localSyncChangesToMergeCoreDataFactory managedObjectContext];
    [_localSyncChangesToMergeContext setUndoManager:nil];

    return _localSyncChangesToMergeContext;
}

- (TICoreDataFactory *)localSyncChangesToMergeCoreDataFactory
{
    if (_localSyncChangesToMergeCoreDataFactory) {
        return _localSyncChangesToMergeCoreDataFactory;
    }

    if (self.localSyncChangesToMergeLocation == nil) {
        return nil;
    }

    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _localSyncChangesToMergeCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeDataModelName];
    [_localSyncChangesToMergeCoreDataFactory setDelegate:self];
    [_localSyncChangesToMergeCoreDataFactory setPersistentStoreType:TICDSSyncChangesCoreDataPersistentStoreType];
    [_localSyncChangesToMergeCoreDataFactory setPersistentStoreDataPath:[self.localSyncChangesToMergeLocation path]];

    return _localSyncChangesToMergeCoreDataFactory;
}

- (TICDSSynchronizationOperationManagedObjectContext *)backgroundApplicationContext
{
    if (_backgroundApplicationContext) {
        return _backgroundApplicationContext;
    }

    _backgroundApplicationContext = [[TICDSSynchronizationOperationManagedObjectContext alloc] init];
    [_backgroundApplicationContext setPersistentStoreCoordinator:self.primaryPersistentStoreCoordinator];
    [_backgroundApplicationContext setUndoManager:nil];

    [[NSNotificationCenter defaultCenter] addObserver:[self delegate] selector:@selector(backgroundManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:_backgroundApplicationContext];

    return _backgroundApplicationContext;
}

- (NSNumberFormatter *)uuidPrefixFormatter
{
    if (_uuidPrefixFormatter == nil) {
        _uuidPrefixFormatter = [[NSNumberFormatter alloc] init];
        [_uuidPrefixFormatter setPositiveFormat:@"0000000000.000000"];
    }

    return _uuidPrefixFormatter;
}

#pragma mark - Properties
@synthesize paused = _paused;
@synthesize mostRecentConflictResolutionType = _mostRecentConflictResolutionType;
@synthesize otherSynchronizedClientDeviceIdentifiers = _otherSynchronizedClientDeviceIdentifiers;
@synthesize otherSynchronizedClientDeviceSyncChangeSetIdentifiers = _otherSynchronizedClientDeviceSyncChangeSetIdentifiers;
@synthesize syncChangeSortDescriptors = _syncChangeSortDescriptors;
@synthesize synchronizationWarnings = _synchronizationWarnings;

@synthesize localSyncChangesToMergeLocation = _localSyncChangesToMergeLocation;
@synthesize appliedSyncChangeSetsFileLocation = _appliedSyncChangeSetsFileLocation;
@synthesize unappliedSyncChangesDirectoryLocation = _unappliedSyncChangesDirectoryLocation;
@synthesize unappliedSyncChangeSetsFileLocation = _unappliedSyncChangeSetsFileLocation;
@synthesize localRecentSyncFileLocation = _localRecentSyncFileLocation;

@synthesize appliedSyncChangeSetsCoreDataFactory = _appliedSyncChangeSetsCoreDataFactory;
@synthesize appliedSyncChangeSetsContext = _appliedSyncChangeSetsContext;
@synthesize unappliedSyncChangeSetsCoreDataFactory = _unappliedSyncChangeSetsCoreDataFactory;
@synthesize unappliedSyncChangeSetsContext = _unappliedSyncChangeSetsContext;
@synthesize unappliedSyncChangesCoreDataFactory = _unappliedSyncChangesCoreDataFactory;
@synthesize unappliedSyncChangesContext = _unappliedSyncChangesContext;
@synthesize localSyncChangesToMergeCoreDataFactory = _localSyncChangesToMergeCoreDataFactory;
@synthesize localSyncChangesToMergeContext = _localSyncChangesToMergeContext;
@synthesize primaryPersistentStoreCoordinator = _primaryPersistentStoreCoordinator;
@synthesize backgroundApplicationContext = _backgroundApplicationContext;

@synthesize numberOfSyncChangeSetIDArraysToFetch = _numberOfSyncChangeSetIDArraysToFetch;
@synthesize numberOfSyncChangeSetIDArraysFetched = _numberOfSyncChangeSetIDArraysFetched;
@synthesize numberOfSyncChangeSetIDArraysThatFailedToFetch = _numberOfSyncChangeSetIDArraysThatFailedToFetch;
@synthesize numberOfUnappliedSyncChangeSetsToFetch = _numberOfUnappliedSyncChangeSetsToFetch;
@synthesize numberOfUnappliedSyncChangeSetsFetched = _numberOfUnappliedSyncChangeSetsFetched;
@synthesize numberOfUnappliedSyncChangeSetsThatFailedToFetch = _numberOfUnappliedSyncChangeSetsThatFailedToFetch;

@synthesize integrityKey = _integrityKey;
@synthesize changeSetProgressString = _changeSetProgressString;
@synthesize uuidPrefixFormatter = _uuidPrefixFormatter;

@end
