//
//  TICDSSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSSynchronizationOperation () <TICoreDataFactoryDelegate>

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
- (NSArray *)syncChangesAfterCheckingForConflicts:(NSArray *)syncChanges;
- (NSArray *)remoteSyncChangesForObjectWithIdentifier:(NSString *)anIdentifier afterCheckingForConflictsInRemoteSyncChanges:(NSArray *)remoteSyncChanges;
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
    if( !aKey && [self error] ) {
        
    }
    
    if( !aKey ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch an integrity key: %@", [[self error] localizedDescription]);
        
        [self operationDidFailToComplete];
        return;
    }
    
    if( [self integrityKey] && ![[self integrityKey] isEqualToString:aKey] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"The keys do not match: got %@, expecting %@", aKey, [self integrityKey]);
        
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
    if( !anArray ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching list of client device identifiers");
        [self operationDidFailToComplete];
        return;
    }
    
    NSMutableArray *clientIdentifiers = [NSMutableArray arrayWithCapacity:[anArray count]];
    
    for( NSString *eachClientIdentifier in anArray ) {
        if( [eachClientIdentifier isEqualToString:[self clientIdentifier]] ) {
            continue;
        }
        
        [clientIdentifiers addObject:eachClientIdentifier];
    }
    
    if( [clientIdentifiers count] < 1 ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No other clients are synchronizing with this document, so skipping to upload local sync commands");
        [self beginUploadOfLocalSyncCommands];
    }
    
    [self setOtherSynchronizedClientDeviceIdentifiers:clientIdentifiers];
    
    [self beginFetchOfListOfSyncCommandSetIdentifiers];
}

#pragma Overridden Method
- (void)buildArrayOfClientDeviceIdentifiers
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self builtArrayOfClientDeviceIdentifiers:nil];
}

#pragma mark - LIST OF SYNC COMMAND SETS
- (void)beginFetchOfListOfSyncCommandSetIdentifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fetch list of SyncCommandSet identifiers for clients %@", [self otherSynchronizedClientDeviceIdentifiers]);
    
    // TODO: Fetch of Sync Commands
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"***Not yet implemented*** so 'finished' fetch of local sync commands");
    
    [self beginFetchOfListOfSyncChangeSetIdentifiers];
}

#pragma mark - LIST OF SYNC CHANGE SETS
- (void)beginFetchOfListOfSyncChangeSetIdentifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Starting to fetch list of SyncChangeSet identifiers");
    
    [self setNumberOfSyncChangeSetIDArraysToFetch:[[self otherSynchronizedClientDeviceIdentifiers] count]];
    
    [self setOtherSynchronizedClientDeviceSyncChangeSetIdentifiers:[NSMutableDictionary dictionaryWithCapacity:[[self otherSynchronizedClientDeviceIdentifiers] count]]];
    
    for( NSString *eachClientIdentifier in [self otherSynchronizedClientDeviceIdentifiers] ) {
        [self buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:eachClientIdentifier];
    }
}

- (void)builtArrayOfClientSyncChangeSetIdentifiers:(NSArray *)anArray forClientIdentifier:(NSString *)aClientIdentifier
{
    if( !anArray ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Failed to fetch an array of client sync change set identifiers for client identifier: %@", aClientIdentifier);
        [self increaseNumberOfSyncChangeSetIdentifierArraysThatFailedToFetch];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched an array of client sync change set identifiers");
        [self increaseNumberOfSyncChangeSetIdentifierArraysFetched];
        anArray = [self unappliedSyncChangeSetIdentifiersFromAvailableSyncChangeSetIdentifiers:anArray];
    }
    
    if( [anArray count] > 0 ) {
        [[self otherSynchronizedClientDeviceSyncChangeSetIdentifiers] setValue:anArray forKey:aClientIdentifier];
    }
    
    if( [self numberOfSyncChangeSetIDArraysToFetch] == [self numberOfSyncChangeSetIDArraysFetched] ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finished fetching client sync change set IDs");
        
        [self beginFetchOfUnappliedSyncChanges];
    } else if( [self numberOfSyncChangeSetIDArraysToFetch] == [self numberOfSyncChangeSetIDArraysFetched] + [self numberOfSyncChangeSetIDArraysThatFailedToFetch] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"One or more sync change set IDs failed to fetch");
        [self operationDidFailToComplete];
    }
}

- (NSArray *)unappliedSyncChangeSetIdentifiersFromAvailableSyncChangeSetIdentifiers:(NSArray *)changeSetIdentifiers
{
    NSMutableArray *addedIdentifiers = [NSMutableArray array];
    
    for( NSString *eachIdentifier in changeSetIdentifiers ) {
        if( [self syncChangeSetHasBeenAppliedWithIdentifier:eachIdentifier] ) {
            continue;
        }
        
        [addedIdentifiers addObject:eachIdentifier];
    }
    
    return addedIdentifiers;
}

- (BOOL)syncChangeSetHasBeenAppliedWithIdentifier:(NSString *)anIdentifier
{
    return [TICDSSyncChangeSet hasSyncChangeSetWithIdentifer:anIdentifier alreadyBeenAppliedInManagedObjectContext:[self appliedSyncChangeSetsContext]];
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
    
    if( [[self otherSynchronizedClientDeviceSyncChangeSetIdentifiers] count] < 1 ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No unapplied sync change sets to download and apply");
        
        [self beginUploadOfLocalSyncCommands];
        return;
    }
    
    NSString *unappliedSyncChangesPath = [[self unappliedSyncChangesDirectoryLocation] path];
    
    for( NSString *eachClientIdentifier in [self otherSynchronizedClientDeviceSyncChangeSetIdentifiers] ) {
        NSArray *syncChangeSets = [[self otherSynchronizedClientDeviceSyncChangeSetIdentifiers] valueForKey:eachClientIdentifier];
        
        [self setNumberOfUnappliedSyncChangeSetsToFetch:[self numberOfUnappliedSyncChangeSetsToFetch] + [syncChangeSets count]];
    }
    
    NSString *fileLocation = nil;
    NSError *anyError = nil;
    for( NSString *eachClientIdentifier in [self otherSynchronizedClientDeviceSyncChangeSetIdentifiers] ) {
        NSArray *syncChangeSets = [[self otherSynchronizedClientDeviceSyncChangeSetIdentifiers] valueForKey:eachClientIdentifier];
        
        for( NSString *eachSyncChangeSetIdentifier in syncChangeSets ) {
            fileLocation = [unappliedSyncChangesPath stringByAppendingPathComponent:eachSyncChangeSetIdentifier];
            fileLocation = [fileLocation stringByAppendingPathExtension:TICDSSyncChangeSetFileExtension];
            
            if( [[self fileManager] fileExistsAtPath:fileLocation] && ![[self fileManager] removeItemAtPath:fileLocation error:&anyError] ) {
                TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to remove existing downloaded but unapplied sync change set %@", eachSyncChangeSetIdentifier);
            }
            
            [self fetchSyncChangeSetWithIdentifier:eachSyncChangeSetIdentifier forClientIdentifier:eachClientIdentifier toLocation:[NSURL fileURLWithPath:fileLocation]];
        }
    }
}

- (void)fetchedSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientIdentifier:(NSString *)aClientIdentifier modificationDate:(NSDate *)aDate withSuccess:(BOOL)success
{
    if( success ) {
        success = [self addUnappliedSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientWithIdentifier:aClientIdentifier modificationDate:aDate];
    }
    
    if( success ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched an unapplied sync change set");
        [self increaseNumberOfUnappliedSyncChangeSetsFetched];
    } else {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch an unapplied sync change set");
        [self increaseNumberOfUnappliedSyncChangeSetsThatFailedToFetch];
    }
    
    if( [self numberOfUnappliedSyncChangeSetsToFetch] == [self numberOfUnappliedSyncChangeSetsFetched] ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finished fetching unapplied sync change sets");
        NSError *anyError = nil;
        BOOL saveSuccess = [[self unappliedSyncChangeSetsContext] save:&anyError];
        if( !saveSuccess ) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save UnappliedSyncChanges.ticdsync file: %@", anyError);
        }
        [self beginApplyingUnappliedSyncChangeSets];
    } else if( [self numberOfUnappliedSyncChangeSetsToFetch] == [self numberOfUnappliedSyncChangeSetsFetched] + [self numberOfUnappliedSyncChangeSetsThatFailedToFetch] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"One of more sync change sets failed to be fetched");
        [self operationDidFailToComplete];
    }
}

- (BOOL)addUnappliedSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientWithIdentifier:(NSString *)aClientIdentifier modificationDate:(NSDate *)aDate
{
    // Check whether it already exists
    NSError *anyError = nil;
    
    TICDSSyncChangeSet *set = [TICDSSyncChangeSet ti_firstObjectMatchingPredicate:[NSPredicate predicateWithFormat:@"syncChangeSetIdentifier == %@", aChangeSetIdentifier] inManagedObjectContext:[self unappliedSyncChangeSetsContext] error:&anyError];
    
    if( set ) {
        return YES;
    }
    
    if( anyError ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataFetchError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to add unapplied sync change set to UnappliedSyncChangeSets.ticdsync: %@", anyError);
        return NO;
    }
    
    set = [TICDSSyncChangeSet syncChangeSetWithIdentifier:aChangeSetIdentifier fromClient:aClientIdentifier creationDate:aDate inManagedObjectContext:[self unappliedSyncChangeSetsContext]];
    
    if( !set ) {
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

#pragma mark -
#pragma mark APPLICATION OF UNAPPLIED SYNC CHANGE SETS
- (void)beginApplyingUnappliedSyncChangeSets
{
    if( [NSThread isMainThread] ) {
        [self performSelectorInBackground:@selector(beginApplyingUnappliedSyncChangeSets) withObject:nil];
        return;
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Checking how many sync change sets need to be applied");
    
    NSError *anyError = nil;
    NSArray *syncChangeSetsToApply = [TICDSSyncChangeSet ti_allObjectsInManagedObjectContext:[self unappliedSyncChangeSetsContext] sortedByKey:@"creationDate" ascending:YES error:&anyError];
    
    if( !syncChangeSetsToApply ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataFetchError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [pool drain];
        [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
        return;
    }
    
    if( [syncChangeSetsToApply count] < 1 ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No other clients have uploaded any sync change sets, so proceeding to upload local sync commands");
        [pool drain];
        [self continueAfterApplyingUnappliedSyncChangeSetsSuccessfully];
        return;
    }
    
    [self setSynchronizationWarnings:[NSMutableArray arrayWithCapacity:20]];
    
    BOOL shouldContinue = [self applyUnappliedSyncChangeSets:syncChangeSetsToApply];
    
    if( shouldContinue ) {
        anyError = nil;
        
        // Save Background Context (changes made to objects in application's context)
        BOOL success = [[self backgroundApplicationContext] save:&anyError];
        if( !success ) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save background context: %@", anyError);
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [pool drain];
            [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
            return;
        }
        
        // Save UnsynchronizedSyncChanges context (UnsynchronizedSyncChanges.syncchg file)
        if( [self localSyncChangesToMergeContext] && ![[self localSyncChangesToMergeContext] save:&anyError] ) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save unsynchroinzed sync changes context, after saving background context: %@", anyError);
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [pool drain];
            [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
            return;
        }
        
        // Save Applied Sync Change Sets context (AppliedSyncChangeSets.ticdsync file)
        success = [[self appliedSyncChangeSetsContext] save:&anyError];
        if( !success ) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save applied sync change sets context, after saving background context: %@", anyError);
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [pool drain];
            [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
            return;
        }
        
        // Save Unapplied Sync Change Sets context (UnappliedSYncChangeSets.ticdsync file)
        success = [[self unappliedSyncChangeSetsContext] save:&anyError];
        if( !success ) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save unapplied sync change sets context, after saving applied sync change sets context: %@", anyError);
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [pool drain];
            [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
            return;
        }
        
        [pool drain];
        [self continueAfterApplyingUnappliedSyncChangeSetsSuccessfully];
    } else {
        [pool drain];
        [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
    }
}

- (BOOL)applyUnappliedSyncChangeSets:(NSArray *)syncChangeSets
{
    BOOL shouldContinue = YES;
    
    for( TICDSSyncChangeSet *eachChangeSet in syncChangeSets ) {
        shouldContinue = [self beginApplyingSyncChangesInChangeSet:eachChangeSet];
        if( !shouldContinue ) {
            break;
        }
        
        shouldContinue = [self addSyncChangeSetToAppliedSyncChangeSets:eachChangeSet];
        if( !shouldContinue ) {
            break;
        }
        
        shouldContinue = [self removeSyncChangeSetFileForSyncChangeSet:eachChangeSet];
        if( !shouldContinue ) {
            break;
        }
        
        // Finally, remove the change set from the UnappliedSyncChangeSets context;
        [[self unappliedSyncChangeSetsContext] deleteObject:eachChangeSet];
    }
    
    return shouldContinue;
}

- (BOOL)addSyncChangeSetToAppliedSyncChangeSets:(TICDSSyncChangeSet *)aChangeSet
{
    TICDSSyncChangeSet *appliedSyncChangeSet = [TICDSSyncChangeSet changeSetWithIdentifier:[aChangeSet syncChangeSetIdentifier] inManagedObjectContext:[self appliedSyncChangeSetsContext]];
    
    if( !appliedSyncChangeSet ) {
        appliedSyncChangeSet = [TICDSSyncChangeSet syncChangeSetWithIdentifier:[aChangeSet syncChangeSetIdentifier] fromClient:[aChangeSet clientIdentifier] creationDate:[aChangeSet creationDate] inManagedObjectContext:[self appliedSyncChangeSetsContext]];
    }
    
    if( !appliedSyncChangeSet ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Unable to create sync change set in applied sync change sets context");
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeObjectCreationError classAndMethod:__PRETTY_FUNCTION__]];
        return NO;
    }
    
    [appliedSyncChangeSet setLocalDateOfApplication:[NSDate date]];
    
    return YES;
}

- (BOOL)removeSyncChangeSetFileForSyncChangeSet:(TICDSSyncChangeSet *)aChangeSet
{
    NSString *pathToSyncChangeSetFile = [[self unappliedSyncChangesDirectoryLocation] path];
    pathToSyncChangeSetFile = [pathToSyncChangeSetFile stringByAppendingPathComponent:[aChangeSet fileName]];
    
    if( ![[self fileManager] fileExistsAtPath:pathToSyncChangeSetFile] ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Sync change set just applied no longer seems to exist on disc, which is strange, but not fatal, so continuing");
        return YES;
    }
    
    NSError *anyError = nil;
    BOOL success = [[self fileManager] removeItemAtPath:pathToSyncChangeSetFile error:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to delete sync change set file from disc; not fatal, so continuing: %@", anyError);
        return YES;
    }
    
    return YES;
}

- (void)continueAfterApplyingUnappliedSyncChangeSetsSuccessfully
{
    if( [self needsMainThread] && ![NSThread isMainThread] ) {
        [self performSelectorOnMainThread:@selector(continueAfterApplyingUnappliedSyncChangeSetsSuccessfully) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self beginUploadOfLocalSyncCommands];
}

- (void)continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully
{
    if( [self needsMainThread] && ![NSThread isMainThread] ) {
        [self performSelectorOnMainThread:@selector(continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self operationDidFailToComplete];
}

#pragma mark -
#pragma mark APPLYING EACH CHANGE SET
- (BOOL)beginApplyingSyncChangesInChangeSet:(TICDSSyncChangeSet *)aChangeSet
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying change set %@", [aChangeSet syncChangeSetIdentifier]);
    
    NSManagedObjectContext *syncChangesContext = [self contextForSyncChangesInUnappliedSyncChangeSet:aChangeSet];
    
    NSError *anyError = nil;
    NSArray *syncChanges = [TICDSSyncChange ti_allObjectsInManagedObjectContext:syncChangesContext sortedWithDescriptors:[self syncChangeSortDescriptors] error:&anyError];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"There are %u changes in this set", [syncChanges count]);
    
    syncChanges = [self syncChangesAfterCheckingForConflicts:syncChanges];
	NSSortDescriptor *sequenceSort = [[NSSortDescriptor alloc] initWithKey:@"changeType" ascending:YES];
    syncChanges = [syncChanges sortedArrayUsingDescriptors:[NSArray arrayWithObject:sequenceSort]];
    [sequenceSort release], sequenceSort = nil;
    
    // Apply each object's changes in turn
    for( TICDSSyncChange *eachChange in syncChanges ) {
        switch( [[eachChange changeType] unsignedIntegerValue] ) {
            case TICDSSyncChangeTypeObjectInserted:
                [self applyObjectInsertedSyncChange:eachChange];
                [[self backgroundApplicationContext] processPendingChanges];
                break;
                
            case TICDSSyncChangeTypeAttributeChanged:
                [self applyAttributeChangeSyncChange:eachChange];
                break;
                
            case TICDSSyncChangeTypeToOneRelationshipChanged:
                [self applyToOneRelationshipSyncChange:eachChange];
                break;
                
            case TICDSSyncChangeTypeToManyRelationshipChangedByAddingObject:
            case TICDSSyncChangeTypeToManyRelationshipChangedByRemovingObject:
                [self applyToManyRelationshipSyncChange:eachChange];
                break;
                
            case TICDSSyncChangeTypeObjectDeleted:
                [self applyObjectDeletedSyncChange:eachChange];
                break;
        }
    }
    
    [[self backgroundApplicationContext] processPendingChanges];
    
    return YES;
}

- (NSManagedObjectContext *)contextForSyncChangesInUnappliedSyncChangeSet:(TICDSSyncChangeSet *)aChangeSet
{
    [self setUnappliedSyncChangesContext:nil];
    [self setUnappliedSyncChangesCoreDataFactory:nil];
    
    TICoreDataFactory *factory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeDataModelName];
    [factory setDelegate:self];
    [factory setPersistentStoreType:TICDSSyncChangesCoreDataPersistentStoreType];
    [factory setPersistentStoreDataPath:[[[self unappliedSyncChangesDirectoryLocation] path] stringByAppendingPathComponent:[aChangeSet fileName]]];
    
    [self setUnappliedSyncChangesCoreDataFactory:factory];
    
    [self setUnappliedSyncChangesContext:[factory managedObjectContext]];
    
    [factory release];
    
    return [self unappliedSyncChangesContext];
}

#pragma mark Conflicts
- (NSArray *)syncChangesAfterCheckingForConflicts:(NSArray *)syncChanges
{
    NSArray *identifiersOfAffectedObjects = [syncChanges valueForKeyPath:@"@distinctUnionOfObjects.objectSyncID"];
    TICDSLog(TICDSLogVerbosityEveryStep, @"Affected Object identifiers: %@", [identifiersOfAffectedObjects componentsJoinedByString:@", "]);
    
    if( ![self localSyncChangesToMergeContext] ) {
        return syncChanges;
    }
    
    NSMutableArray *syncChangesToReturn = [NSMutableArray arrayWithCapacity:[syncChanges count]];
    
    NSArray *syncChangesForEachObject = nil;
    for( NSString *eachIdentifier in identifiersOfAffectedObjects ) {
        syncChangesForEachObject = [syncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"objectSyncID == %@", eachIdentifier]];
        
        syncChangesForEachObject = [self remoteSyncChangesForObjectWithIdentifier:eachIdentifier afterCheckingForConflictsInRemoteSyncChanges:syncChangesForEachObject];
        [syncChangesToReturn addObjectsFromArray:syncChangesForEachObject];
    }
    
    return syncChangesToReturn;
}

- (NSArray *)remoteSyncChangesForObjectWithIdentifier:(NSString *)anIdentifier afterCheckingForConflictsInRemoteSyncChanges:(NSArray *)remoteSyncChanges
{
    NSError *anyError = nil;
    NSArray *localSyncChanges = [TICDSSyncChange ti_objectsMatchingPredicate:[NSPredicate predicateWithFormat:@"objectSyncID == %@", anIdentifier] inManagedObjectContext:[self localSyncChangesToMergeContext] sortedByKey:@"changeType" ascending:YES error:&anyError];
    
// Used to trigger faults on all objects if debugging     
/*    NSArray *allSyncChanges = [TICDSSyncChange ti_allObjectsInManagedObjectContext:[self localSyncChangesToMergeContext] error:&anyError];
    for( TICDSSyncChange *eachChange in allSyncChanges ) {
        NSString *something = [eachChange objectEntityName];
        something = [eachChange relatedObjectEntityName];
    }
*/    
    if( !localSyncChanges ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch local sync changes while checking for conflicts: %@", anyError);
        return remoteSyncChanges;
    }
    
    if( [localSyncChanges count] < 1 ) {
        // No matching local sync changes, so all remote changes can be processed
        return remoteSyncChanges;
    }
    
    NSMutableArray *remoteSyncChangesToReturn = [NSMutableArray arrayWithArray:remoteSyncChanges];
    
    // Check if remote has deleted an object that has been changed locally
    NSArray *deletionChanges = [remoteSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeObjectDeleted]];
    if( [deletionChanges count] > 0 ) {
        // remote has deleted an object, so add warnings for all local changes
        [self addWarningsForRemoteDeletionWithLocalChanges:localSyncChanges];
        
        // Delete all local sync changes for this object
        for( TICDSSyncChange *eachLocalChange in localSyncChanges ) {
            [[self localSyncChangesToMergeContext] deleteObject:eachLocalChange];
        }
    }
    
    // Check if remote has changed attributes on an object that has been deleted locally
    NSArray *changeChanges = [remoteSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeAttributeChanged]];
    deletionChanges = [localSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeObjectDeleted]];
    
    if( [changeChanges count] > 0 && [deletionChanges count] > 0 ) {
        // remote has changed an object, so add warnings for each of the changes
        [self addWarningsForRemoteChangesWithLocalDeletion:changeChanges];
        
        // Remove change sync changs from remoteSyncChanges
        [remoteSyncChangesToReturn removeObjectsInArray:changeChanges];
    }
    
    // Check if remote has changed an object's attribute and local has changed the same object attribute
    NSArray *remoteAttributeChanges = [remoteSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeAttributeChanged]];
    NSArray *localAttributeChanges = [localSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeAttributeChanged]];
    for( TICDSSyncChange *eachRemoteChange in remoteAttributeChanges ) {
        // check the attribute name against each local attribute name
        for( TICDSSyncChange *eachLocalChange in localAttributeChanges ) {
            if( ![[eachLocalChange relevantKey] isEqualToString:[eachRemoteChange relevantKey]] ) {
                continue;
            }
            
            if( [[eachLocalChange changedAttributes] isEqual:[eachRemoteChange changedAttributes]] ) {
                // both changes changed the value to the same thing so remove the local, unpushed sync change
                [[self localSyncChangesToMergeContext] deleteObject:eachLocalChange];
                continue;
            }
            
            // if we get here, we have a conflict between eachRemoteChange and eachLocalChange
            TICDSSyncConflict *conflict = [TICDSSyncConflict syncConflictOfType:TICDSSyncConflictRemoteAttributeChangedAndLocalAttributeChanged forEntityName:[eachLocalChange objectEntityName] key:[eachLocalChange relevantKey] objectSyncID:[eachLocalChange objectSyncID]];
            [conflict setLocalInformation:[NSDictionary dictionaryWithObject:[eachLocalChange changedAttributes] forKey:kTICDSChangedAttributeValue]];
            [conflict setRemoteInformation:[NSDictionary dictionaryWithObject:[eachRemoteChange changedAttributes] forKey:kTICDSChangedAttributeValue]];
            TICDSSyncConflictResolutionType resolutionType = [self resolutionTypeForConflict:conflict];
            
            if( [self isCancelled] ) {
                [self operationWasCancelled];
                return nil;
            }
            
            if( resolutionType == TICDSSyncConflictResolutionTypeRemoteWins ) {
                // just delete the local sync change so the remote change wins
                [[self localSyncChangesToMergeContext] deleteObject:eachLocalChange];
            } else if( resolutionType == TICDSSyncConflictResolutionTypeLocalWins ) {
                // remove the remote sync change so it's not applied
                [remoteSyncChangesToReturn removeObject:eachRemoteChange];
            }
        }
    }
    
    return remoteSyncChangesToReturn;
}

- (void)addWarningsForRemoteDeletionWithLocalChanges:(NSArray *)localChanges
{
    for( TICDSSyncChange *eachLocalChange in localChanges ) {
        switch( [[eachLocalChange changeType] unsignedIntegerValue] ) {
            case TICDSSyncChangeTypeAttributeChanged:
                [[self synchronizationWarnings] addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectWithAttributesChangedLocallyAlreadyDeletedByRemoteSyncChange entityName:[eachLocalChange objectEntityName] relatedObjectEntityName:nil attributes:[eachLocalChange changedAttributes]]];
                break;
        }
    }
}

- (void)addWarningsForRemoteChangesWithLocalDeletion:(NSArray *)remoteChanges
{
    for( TICDSSyncChange *eachRemoteChange in remoteChanges ) {
        switch( [[eachRemoteChange changeType] unsignedIntegerValue] ) {
            case TICDSSyncChangeTypeAttributeChanged:
                [[self synchronizationWarnings] addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectWithAttributesChangedRemotelyNowDeletedByLocalSyncChange entityName:[eachRemoteChange objectEntityName] relatedObjectEntityName:nil attributes:[eachRemoteChange changedAttributes]]];
                break;
                
            case TICDSSyncChangeTypeToOneRelationshipChanged:
            case TICDSSyncChangeTypeToManyRelationshipChangedByAddingObject:
            case TICDSSyncChangeTypeToManyRelationshipChangedByRemovingObject:
                [[self synchronizationWarnings] addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectWithRelationshipsChangedRemotelyNowDeletedByLocalSyncChange entityName:[eachRemoteChange objectEntityName] relatedObjectEntityName:[eachRemoteChange relatedObjectEntityName] attributes:nil]];
                break;
        }
    }
}

- (TICDSSyncConflictResolutionType)resolutionTypeForConflict:(TICDSSyncConflict *)aConflict
{
    [self setPaused:YES];
        
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(synchronizationOperation:pausedToDetermineResolutionOfConflict:) waitUntilDone:YES, aConflict];
    
    while( [self isPaused] && ![self isCancelled] ) {
        [NSThread sleepForTimeInterval:0.2];
    }
    
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(synchronizationOperationResumedFollowingResolutionOfConflict:) waitUntilDone:YES];
    
    return [self mostRecentConflictResolutionType];
}

#pragma mark Fetching Affected Objects
- (NSManagedObject *)backgroundApplicationContextObjectForEntityName:(NSString *)entityName syncIdentifier:(NSString *)aSyncIdentifier
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:[self backgroundApplicationContext]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", TICDSSyncIDAttributeName, aSyncIdentifier]];
    
    NSError *anyError = nil;
    NSArray *results = [[self backgroundApplicationContext] executeFetchRequest:fetchRequest error:&anyError];
    if( !results ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching affected object: %@", anyError);
    }
    
    [fetchRequest release];
    
    return [results lastObject];
}

#pragma mark Applying Changes
- (void)applyObjectInsertedSyncChange:(TICDSSyncChange *)aSyncChange
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Insertion sync change");
    
    NSString *entityName = [aSyncChange objectEntityName];
    NSString *ticdsSyncID = aSyncChange.objectSyncID;
    NSManagedObject *object = nil;
    
    // Check to see if the object already exists before inserting it.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:[self backgroundApplicationContext]]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"%K == %@", TICDSSyncIDAttributeName, ticdsSyncID]];
    
    NSError *anyError = nil;
    NSArray *results = [[self backgroundApplicationContext] executeFetchRequest:fetchRequest error:&anyError];
    if ([results count] == 0) {
        object = [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:[self backgroundApplicationContext]];
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Inserted object: %@", object);
    } else {
        object = [results lastObject];
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Attempted to insert an object that already existed, updating existing object instead.: %@", object);
    }
    
    [object setValuesForKeysWithDictionary:[aSyncChange changedAttributes]];

    [fetchRequest release];
    
}

- (void)applyAttributeChangeSyncChange:(TICDSSyncChange *)aSyncChange
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Attribute Change sync change");
    
    NSManagedObject *object = [self backgroundApplicationContextObjectForEntityName:[aSyncChange objectEntityName] syncIdentifier:[aSyncChange objectSyncID]];
    
    if( !object ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object not found locally for attribute change"); 
        [[self synchronizationWarnings] addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteAttributeSyncChange entityName:[aSyncChange objectEntityName] relatedObjectEntityName:nil attributes:[aSyncChange changedAttributes]]];
        return;
    }
    
    [object setValue:[aSyncChange changedAttributes] forKey:[aSyncChange relevantKey]];
    
    TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Changed attribute on object: %@", object);
}

- (void)applyToOneRelationshipSyncChange:(TICDSSyncChange *)aSyncChange
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Relationship Change sync change");
    
    NSManagedObject *object = [self backgroundApplicationContextObjectForEntityName:[aSyncChange objectEntityName] syncIdentifier:[aSyncChange objectSyncID]];
    
    if( !object ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object not found locally for attribute change"); 
        [[self synchronizationWarnings] addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteRelationshipSyncChange entityName:[aSyncChange objectEntityName] relatedObjectEntityName:[aSyncChange relatedObjectEntityName] attributes:[aSyncChange changedAttributes]]];
        return;
    }
    
    NSManagedObject *relatedObject = [self backgroundApplicationContextObjectForEntityName:[aSyncChange relatedObjectEntityName] syncIdentifier:[aSyncChange changedRelationships]];
        
    [object setValue:relatedObject forKey:[aSyncChange relevantKey]];
    
    TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Changed to-one relationship on object: %@", object);
}

- (void)applyToManyRelationshipSyncChange:(TICDSSyncChange *)aSyncChange
{
    NSManagedObject *object = [self backgroundApplicationContextObjectForEntityName:[aSyncChange objectEntityName] syncIdentifier:[aSyncChange objectSyncID]];
    
    if( !object ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object not found locally for attribute change"); 
        [[self synchronizationWarnings] addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteRelationshipSyncChange entityName:[aSyncChange objectEntityName] relatedObjectEntityName:[aSyncChange relatedObjectEntityName] attributes:[aSyncChange changedAttributes]]];
        return;
    }
    
    // capitalize the first char of relationship name to change e.g., someObjects into SomeObjects
    NSString *relationshipName = [[aSyncChange relevantKey] substringToIndex:1];
    relationshipName = [relationshipName capitalizedString];
    relationshipName = [relationshipName stringByAppendingString:[[aSyncChange relevantKey] substringFromIndex:1]];
    
    NSString *selectorName = nil;
    
    if( [[aSyncChange changeType] unsignedIntegerValue] == TICDSSyncChangeTypeToManyRelationshipChangedByAddingObject ) {
        selectorName = [NSString stringWithFormat:@"add%@Object:", relationshipName];
    } else {
        selectorName = [NSString stringWithFormat:@"remove%@Object:", relationshipName];
    }
    
    NSManagedObject *relatedObject = [self backgroundApplicationContextObjectForEntityName:[aSyncChange relatedObjectEntityName] syncIdentifier:[aSyncChange changedRelationships]];
    
    [object performSelector:NSSelectorFromString(selectorName) withObject:relatedObject];
    
    TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Changed to-many relationships on object: %@", object);
}

- (void)applyObjectDeletedSyncChange:(TICDSSyncChange *)aSyncChange
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Deletion sync change");
    
    NSManagedObject *object = [self backgroundApplicationContextObjectForEntityName:[aSyncChange objectEntityName] syncIdentifier:[aSyncChange objectSyncID]];
    
    if( !object ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object not found locally for deletion sync change");
        [[self synchronizationWarnings] addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteDeletionSyncChange entityName:[aSyncChange objectEntityName] relatedObjectEntityName:nil attributes:nil]];
        return;
    }
    
    [[self backgroundApplicationContext] deleteObject:object];
    
    TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Deleted object with ID: %@", [aSyncChange objectSyncID]);
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
    if( ![[self fileManager] fileExistsAtPath:[[self localSyncChangesToMergeLocation] path]] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No local sync changes file to push on this sync");
        [self beginUploadOfRecentSyncFile];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Renaming sync changes file ready for upload");
    
    NSString *identifier = [TICDSUtilities uuidString];
    
    NSString *filePath = [[self localSyncChangesToMergeLocation] path];
    filePath = [filePath stringByDeletingLastPathComponent];
    filePath = [filePath stringByAppendingPathComponent:identifier];
    filePath = [filePath stringByAppendingPathExtension:TICDSSyncChangeSetFileExtension];
    
    NSError *anyError = nil;
    BOOL success = [[self fileManager] moveItemAtPath:[[self localSyncChangesToMergeLocation] path] toPath:filePath error:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to move local sync changes to merge file");
        
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];        
        [self operationDidFailToComplete];
        return;
    }
    
    NSDate *date = [NSDate date];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Adding local sync change set into AppliedSyncChanges");
    TICDSSyncChangeSet *appliedSyncChangeSet = [TICDSSyncChangeSet syncChangeSetWithIdentifier:identifier fromClient:[self clientIdentifier] creationDate:date inManagedObjectContext:[self appliedSyncChangeSetsContext]];
    
    if( !appliedSyncChangeSet ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Unable to create sync change set in applied sync change sets context");
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeObjectCreationError classAndMethod:__PRETTY_FUNCTION__]];
        [self operationDidFailToComplete];
        return;
    }
    
    [appliedSyncChangeSet setLocalDateOfApplication:date];
    
    // Save Applied Sync Change Sets context (AppliedSyncChangeSets.ticdsync file)
    success = [[self appliedSyncChangeSetsContext] save:&anyError];
    if( !success ) {
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
    if( !success ) {
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

#pragma mark -
#pragma mark RECENT SYNC FILE
- (void)beginUploadOfRecentSyncFile
{
    NSString *recentSyncFilePath = [[self localRecentSyncFileLocation] path];
    
    NSDictionary *recentSyncDictionary = [NSDictionary dictionaryWithObject:[NSDate date] forKey:kTICDSLastSyncDate];
    
    BOOL success = [recentSyncDictionary writeToFile:recentSyncFilePath atomically:YES];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to write RecentSync file to helper file location, but not absolutely fatal so continuing");
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    [self uploadRecentSyncFileAtLocation:[NSURL fileURLWithPath:recentSyncFilePath]];
}

- (void)uploadedRecentSyncFileSuccessfully:(BOOL)success
{
    if( !success ) {
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
    [self setNumberOfSyncChangeSetIDArraysToFetch:[self numberOfSyncChangeSetIDArraysToFetch] + 1];
}

- (void)increaseNumberOfSyncChangeSetIdentifierArraysFetched
{
    [self setNumberOfSyncChangeSetIDArraysFetched:[self numberOfSyncChangeSetIDArraysFetched] + 1];
}

- (void)increaseNumberOfSyncChangeSetIdentifierArraysThatFailedToFetch
{
    [self setNumberOfSyncChangeSetIDArraysThatFailedToFetch:[self numberOfSyncChangeSetIDArraysThatFailedToFetch] + 1];
}

- (void)increaseNumberOfUnappliedSyncChangeSetsToFetch
{
    [self setNumberOfUnappliedSyncChangeSetsToFetch:[self numberOfUnappliedSyncChangeSetsToFetch] + 1];
}

- (void)increaseNumberOfUnappliedSyncChangeSetsFetched
{
    [self setNumberOfUnappliedSyncChangeSetsFetched:[self numberOfUnappliedSyncChangeSetsFetched] + 1];
}

- (void)increaseNumberOfUnappliedSyncChangeSetsThatFailedToFetch
{
    [self setNumberOfUnappliedSyncChangeSetsThatFailedToFetch:[self numberOfUnappliedSyncChangeSetsThatFailedToFetch] + 1];
}

#pragma mark -
#pragma mark TICoreDataFactory Delegate
- (void)coreDataFactory:(TICoreDataFactory *)aFactory encounteredError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Applied Sync Change Sets Factory Error: %@", anError);
}

#pragma mark -
#pragma mark Configuration
- (void)configureBackgroundApplicationContextForPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)aPersistentStoreCoordinator
{
    [self setPrimaryPersistentStoreCoordinator:aPersistentStoreCoordinator];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)initWithDelegate:(NSObject<TICDSSynchronizationOperationDelegate> *)aDelegate
{
    return [super initWithDelegate:aDelegate];
}

- (void)dealloc
{
    [_otherSynchronizedClientDeviceIdentifiers release], _otherSynchronizedClientDeviceIdentifiers = nil;
    [_otherSynchronizedClientDeviceSyncChangeSetIdentifiers release], _otherSynchronizedClientDeviceSyncChangeSetIdentifiers = nil;
    [_syncChangeSortDescriptors release], _syncChangeSortDescriptors = nil;
    [_synchronizationWarnings release], _synchronizationWarnings = nil;

    [_localSyncChangesToMergeLocation release], _localSyncChangesToMergeLocation = nil;
    [_appliedSyncChangeSetsFileLocation release], _appliedSyncChangeSetsFileLocation = nil;
    [_unappliedSyncChangesDirectoryLocation release], _unappliedSyncChangesDirectoryLocation = nil;
    [_unappliedSyncChangeSetsFileLocation release], _unappliedSyncChangeSetsFileLocation = nil;
    [_localRecentSyncFileLocation release], _localRecentSyncFileLocation = nil;
    
    [_appliedSyncChangeSetsCoreDataFactory release], _appliedSyncChangeSetsCoreDataFactory = nil;
    [_appliedSyncChangeSetsContext release], _appliedSyncChangeSetsContext = nil;
    [_unappliedSyncChangeSetsCoreDataFactory release], _unappliedSyncChangeSetsCoreDataFactory = nil;
    [_unappliedSyncChangeSetsContext release], _unappliedSyncChangeSetsContext = nil;
    [_unappliedSyncChangesCoreDataFactory release], _unappliedSyncChangesCoreDataFactory = nil;
    [_unappliedSyncChangesContext release], _unappliedSyncChangesContext = nil;
    [_localSyncChangesToMergeCoreDataFactory release], _localSyncChangesToMergeCoreDataFactory = nil;
    [_localSyncChangesToMergeContext release], _localSyncChangesToMergeContext = nil;
    [_primaryPersistentStoreCoordinator release], _primaryPersistentStoreCoordinator = nil;
    [_backgroundApplicationContext release], _backgroundApplicationContext = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Lazy Accessors
- (NSArray *)syncChangeSortDescriptors
{
    if( _syncChangeSortDescriptors ) {
        return _syncChangeSortDescriptors;
    }
    
    _syncChangeSortDescriptors = [[NSArray alloc] initWithObjects:
                                  [[[NSSortDescriptor alloc] initWithKey:@"changeType" ascending:YES] autorelease],
                                  [[[NSSortDescriptor alloc] initWithKey:@"localTimeStamp" ascending:YES] autorelease],
                                  nil];
    
    return _syncChangeSortDescriptors;
}

- (NSManagedObjectContext *)appliedSyncChangeSetsContext
{
    if( _appliedSyncChangeSetsContext ) {
        return _appliedSyncChangeSetsContext;
    }
    
    _appliedSyncChangeSetsContext = [[[self appliedSyncChangeSetsCoreDataFactory] managedObjectContext] retain];
    [_appliedSyncChangeSetsContext setUndoManager:nil];
    
    return _appliedSyncChangeSetsContext;
}

- (TICoreDataFactory *)appliedSyncChangeSetsCoreDataFactory
{
    if( _appliedSyncChangeSetsCoreDataFactory ) {
        return _appliedSyncChangeSetsCoreDataFactory;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _appliedSyncChangeSetsCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeSetDataModelName];
    [_appliedSyncChangeSetsCoreDataFactory setPersistentStoreType:TICDSSyncChangeSetsCoreDataPersistentStoreType];
    [_appliedSyncChangeSetsCoreDataFactory setPersistentStoreDataPath:[[self appliedSyncChangeSetsFileLocation] path]];
    [_appliedSyncChangeSetsCoreDataFactory setDelegate:self];
    
    return _appliedSyncChangeSetsCoreDataFactory;
}

- (NSManagedObjectContext *)unappliedSyncChangeSetsContext
{
    if( _unappliedSyncChangeSetsContext ) {
        return _unappliedSyncChangeSetsContext;
    }
    
    _unappliedSyncChangeSetsContext = [[[self unappliedSyncChangeSetsCoreDataFactory] managedObjectContext] retain];
    [_unappliedSyncChangeSetsContext setUndoManager:nil];
    
    return _unappliedSyncChangeSetsContext;
}

- (TICoreDataFactory *)unappliedSyncChangeSetsCoreDataFactory
{
    if( _unappliedSyncChangeSetsCoreDataFactory ) {
        return _unappliedSyncChangeSetsCoreDataFactory;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _unappliedSyncChangeSetsCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeSetDataModelName];
    [_unappliedSyncChangeSetsCoreDataFactory setPersistentStoreType:TICDSSyncChangeSetsCoreDataPersistentStoreType];
    [_unappliedSyncChangeSetsCoreDataFactory setPersistentStoreDataPath:[[self unappliedSyncChangeSetsFileLocation] path]];
    [_unappliedSyncChangeSetsCoreDataFactory setDelegate:self];
    
    return _unappliedSyncChangeSetsCoreDataFactory;
}

- (NSManagedObjectContext *)localSyncChangesToMergeContext
{
    if( _localSyncChangesToMergeContext ) {
        return _localSyncChangesToMergeContext;
    }
    
    _localSyncChangesToMergeContext = [[[self localSyncChangesToMergeCoreDataFactory] managedObjectContext] retain];
    [_localSyncChangesToMergeContext setUndoManager:nil];
    
    return _localSyncChangesToMergeContext;
}

- (TICoreDataFactory *)localSyncChangesToMergeCoreDataFactory
{
    if( _localSyncChangesToMergeCoreDataFactory ) {
        return _localSyncChangesToMergeCoreDataFactory;
    }
    
    if( ![self localSyncChangesToMergeLocation] ) {
        return nil;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _localSyncChangesToMergeCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeDataModelName];
    [_localSyncChangesToMergeCoreDataFactory setDelegate:self];
    [_localSyncChangesToMergeCoreDataFactory setPersistentStoreType:TICDSSyncChangesCoreDataPersistentStoreType];
    [_localSyncChangesToMergeCoreDataFactory setPersistentStoreDataPath:[[self localSyncChangesToMergeLocation] path]];
    
    return _localSyncChangesToMergeCoreDataFactory;
}

- (TICDSSynchronizationOperationManagedObjectContext *)backgroundApplicationContext
{
    if( _backgroundApplicationContext ) {
        return _backgroundApplicationContext;
    }
    
    _backgroundApplicationContext = [[TICDSSynchronizationOperationManagedObjectContext alloc] init];
    [_backgroundApplicationContext setPersistentStoreCoordinator:[self primaryPersistentStoreCoordinator]];
    [_backgroundApplicationContext setUndoManager:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:[self delegate] selector:@selector(backgroundManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:_backgroundApplicationContext];
    
    return _backgroundApplicationContext;
}

#pragma mark -
#pragma mark Properties
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

@end
