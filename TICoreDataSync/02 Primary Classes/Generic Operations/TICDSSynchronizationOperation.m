//
//  TICDSSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSSynchronizationOperation () <TICoreDataFactoryDelegate>

#pragma mark Properties
/** @name Properties */

/** The sort descriptors used to sort sync change objects in a `SyncChangeSet` before being applied. */
@property (nonatomic, strong) NSArray *syncChangeSortDescriptors;

/** @name Managed Object Contexts and Factories */

/** A `TICoreDataFactory` to access the contents of the `AppliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, strong) TICoreDataFactory *appliedSyncChangeSetsCoreDataFactory;

/** The managed object context for the `AppliedSyncChangeSets.ticdsync` file. */
@property (nonatomic, strong) NSManagedObjectContext *appliedSyncChangeSetsContext;

/** A `TICoreDataFactory` to access the contents of this operation's sync transaction `*.unsavedticdsync` file. */
@property (nonatomic, strong) TICoreDataFactory *unsavedAppliedSyncChangeSetsCoreDataFactory;

/** The managed object context for this operation's sync transaction `*.unsavedticdsync` file. */
@property (nonatomic, strong) NSManagedObjectContext *unsavedAppliedSyncChangeSetsContext;

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

/** The parent managed object context for the application - used to create a background application context, when needed. */
@property (strong) NSManagedObjectContext *primaryManagedObjectContext;

/** The managed object context (tied to the application's persistent store coordinator) in which `SyncChanges` are applied. */
@property (nonatomic, strong) TICDSSynchronizationOperationManagedObjectContext *backgroundApplicationContext;

@property (nonatomic, copy) NSString *changeSetProgressString;

/** Releases any existing `unappliedSyncChangesContext` and `unappliedSyncChangesCoreDataFactory` and sets new ones, linked to the set of sync changes specified in the given sync change set.
 
 @param aChangeSet The `TICDSSyncChangeSet` object specifying the set of changes to use.
 
 @return A managed object context to access the sync changes. */
- (NSManagedObjectContext *)contextForSyncChangesInUnappliedSyncChangeSet:(TICDSSyncChangeSet *)aChangeSet;

@end

@implementation TICDSSynchronizationOperation

- (void)main
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    [self beginApplyingUnappliedSyncChangeSets];
}

#pragma mark - APPLICATION OF UNAPPLIED SYNC CHANGE SETS

- (void)beginApplyingUnappliedSyncChangeSets
{
    if (self.isCancelled) {
        [self operationWasCancelled];
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

            [self.syncTransaction open];
            
            // Save Background Context (changes made to objects in application's context)
            __block BOOL success = NO;
            [self.backgroundApplicationContext performBlockAndWait:^{
                [self.backgroundApplicationContext.parentContext.undoManager disableUndoRegistration];
                success = [[self backgroundApplicationContext] save:&anyError];
                [self.backgroundApplicationContext.parentContext.undoManager enableUndoRegistration];
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
            success = [self.unsavedAppliedSyncChangeSetsContext save:&anyError];
            if (success == NO) {
                TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save unsaved applied sync change sets context, after saving background context: %@", anyError);
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeCoreDataSaveError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                [self continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully];
                return;
            }

            // Save Unapplied Sync Change Sets context (UnappliedSyncChangeSets.ticdsync file)
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
        if (self.isCancelled) {
            [self operationWasCancelled];
            return NO;
        }
        
        @autoreleasepool {
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
    }

    return shouldContinue;
}

- (BOOL)addSyncChangeSetToAppliedSyncChangeSets:(TICDSSyncChangeSet *)previouslyUnappliedSyncChangeSet
{
    NSString *syncChangeSetIdentifier = previouslyUnappliedSyncChangeSet.syncChangeSetIdentifier;
    NSString *clientIdentifier = previouslyUnappliedSyncChangeSet.clientIdentifier;
    NSDate *creationDate = previouslyUnappliedSyncChangeSet.creationDate;

    TICDSSyncChangeSet *appliedSyncChangeSet = [TICDSSyncChangeSet changeSetWithIdentifier:syncChangeSetIdentifier inManagedObjectContext:self.appliedSyncChangeSetsContext];

    if (appliedSyncChangeSet == nil) {
        appliedSyncChangeSet = [TICDSSyncChangeSet changeSetWithIdentifier:syncChangeSetIdentifier inManagedObjectContext:self.unsavedAppliedSyncChangeSetsContext];
    }

    if (appliedSyncChangeSet == nil) {
        appliedSyncChangeSet = [TICDSSyncChangeSet syncChangeSetWithIdentifier:syncChangeSetIdentifier fromClient:clientIdentifier creationDate:creationDate inManagedObjectContext:self.unsavedAppliedSyncChangeSetsContext];
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
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if ([self needsMainThread] && ![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(continueAfterApplyingUnappliedSyncChangeSetsSuccessfully) withObject:nil waitUntilDone:NO];
        return;
    }

    [self operationDidCompleteSuccessfully];
}

- (void)continueAfterApplyingUnappliedSyncChangeSetsUnsuccessfully
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
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
    NSString *clientIdentifier = unappliedSyncChangeSet.clientIdentifier;
    
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
        if (self.isCancelled) {
            [self operationWasCancelled];
            return NO;
        }
        
        @autoreleasepool {
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
            
            [eachChange.managedObjectContext refreshObject:eachChange mergeChanges:NO];
        }

        changeCount++;
        if ([self ti_delegateRespondsToSelector:@selector(synchronizationOperation:processedChangeNumber:outOfTotalChangeCount:fromClientWithID:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                               [(id)self.delegate synchronizationOperation:self processedChangeNumber:[NSNumber numberWithInteger:changeCount] outOfTotalChangeCount:[NSNumber numberWithInteger:[unappliedSyncChanges count]] fromClientWithID:clientIdentifier];
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
    
    // Check if remote has changed an object's attribute and local has changed the same object attribute
    NSArray *remoteAttributeChanges = [remoteSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeAttributeChanged]];
    NSArray *localAttributeChanges = [localSyncChanges filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"changeType == %u", TICDSSyncChangeTypeAttributeChanged]];
    for( TICDSSyncChange *eachRemoteChange in remoteAttributeChanges ) {
        // check the attribute name against each local attribute name
        for( TICDSSyncChange *eachLocalChange in localAttributeChanges ) {
            if( ![[eachLocalChange relevantKey] isEqualToString:[eachRemoteChange relevantKey]] ) {
                continue;
            }
            
            if( ([eachLocalChange changedAttributes] == nil && [eachRemoteChange changedAttributes] == nil) || [[eachLocalChange changedAttributes] isEqual:[eachRemoteChange changedAttributes]] ) {
                // both changes changed the value to the same thing so remove the local, unpushed sync change
                [[self localSyncChangesToMergeContext] deleteObject:eachLocalChange];
                continue;
            }
            
            // if we get here, we have a conflict between eachRemoteChange and eachLocalChange
            TICDSSyncConflict *conflict = [TICDSSyncConflict syncConflictOfType:TICDSSyncConflictRemoteAttributeChangedAndLocalAttributeChanged forEntityName:[eachLocalChange objectEntityName] key:[eachLocalChange relevantKey] objectSyncID:[eachLocalChange objectSyncID]];
            if ([eachLocalChange changedAttributes] != nil) {
                [conflict setLocalInformation:[NSDictionary dictionaryWithObject:[eachLocalChange changedAttributes] forKey:kTICDSChangedAttributeValue]];
            }
            
            if ([eachRemoteChange changedAttributes] != nil) {
                [conflict setRemoteInformation:[NSDictionary dictionaryWithObject:[eachRemoteChange changedAttributes] forKey:kTICDSChangedAttributeValue]];
            }
            
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

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
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

        [TICDSChangeIntegrityStoreManager addSyncIDToInsertionIntegrityStore:ticdsSyncID];

        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Updated object: %@", insertedObject);
    }];
}

- (void)applyAttributeChangeSyncChange:(TICDSSyncChange *)syncChange
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Attribute Change sync change");
    
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
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

        [TICDSChangeIntegrityStoreManager addChangedAttributeValue:changedAttributes forKey:relevantKey toChangeIntegrityStoreForSyncID:objectSyncID];
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Changed attribute on object: %@", object);
    }];
}

- (void)applyToOneRelationshipSyncChange:(TICDSSyncChange *)syncChange
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Relationship Change sync change");
    
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
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

        [TICDSChangeIntegrityStoreManager addChangedAttributeValue:changedRelationships forKey:relevantKey toChangeIntegrityStoreForSyncID:objectSyncID];

        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Changed to-one relationship on object: %@[%@]", objectEntityName, objectSyncID);
    }];
}

- (void)applyToManyRelationshipSyncChange:(TICDSSyncChange *)syncChange
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    NSString *objectEntityName = syncChange.objectEntityName;
    NSString *objectSyncID = syncChange.objectSyncID;
    id changedAttributes = syncChange.changedAttributes;
    NSString *relevantKey = syncChange.relevantKey;
    NSString *relatedObjectEntityName = syncChange.relatedObjectEntityName;
    id changedRelationships = syncChange.changedRelationships;
    NSNumber *changeType = syncChange.changeType;
    NSString *syncChangeDescription = [NSString stringWithFormat:@"%@", syncChange];
    
    [self.backgroundApplicationContext performBlockAndWait:^{
        NSManagedObject *object = [self backgroundApplicationContextObjectForEntityName:objectEntityName syncIdentifier:objectSyncID];
        
        if (object == nil) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object not found locally for attribute change %@", objectEntityName);
            [self.synchronizationWarnings addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteRelationshipSyncChange entityName:objectEntityName relatedObjectEntityName:relatedObjectEntityName attributes:changedAttributes]];
            return;
        }
        
        // capitalize the first char of relationship name to change e.g., someObject into SomeObject
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
        if (relatedObject == nil) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Could not fetch %@ object with syncIdentifier %@ so bailing from trying to call %@ on our %@", relatedObjectEntityName, changedRelationships, selectorName, objectEntityName);
            [self.synchronizationWarnings addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteRelationshipSyncChange entityName:relatedObjectEntityName relatedObjectEntityName:nil attributes:changedRelationships]];
            return;
        }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([object respondsToSelector:NSSelectorFromString(selectorName)]) {
        [object performSelector:NSSelectorFromString(selectorName) withObject:relatedObject];
    } else {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object does not respond to selector: %@ [%@] %@", selectorName, syncChangeDescription, objectEntityName);
    }
#pragma clang diagnostic pop
        
        [TICDSChangeIntegrityStoreManager addChangedAttributeValue:changedRelationships forKey:relevantKey toChangeIntegrityStoreForSyncID:objectSyncID];

        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"%@", objectEntityName);
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"Changed to-many relationships on object: %@", object);
    }];
}

- (void)applyObjectDeletedSyncChange:(TICDSSyncChange *)syncChange
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    NSString *objectEntityName = syncChange.objectEntityName;
    NSString *objectSyncID = syncChange.objectSyncID;
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Applying Deletion sync change");

    [self.backgroundApplicationContext performBlockAndWait:^{
        NSManagedObject *object = [self backgroundApplicationContextObjectForEntityName:objectEntityName syncIdentifier:objectSyncID];
        
        if (object == nil) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Object not found locally for deletion sync change %@", objectEntityName);
            if (objectSyncID != nil) {
                [self.synchronizationWarnings addObject:[TICDSUtilities syncWarningOfType:TICDSSyncWarningTypeObjectNotFoundLocallyForRemoteDeletionSyncChange entityName:objectEntityName relatedObjectEntityName:nil attributes:@{ @"objectSyncID":objectSyncID}]];
            }

            return;
        }
        
        TICDSLog(TICDSLogVerbosityManagedObjectOutput, @"%@ (%@)", objectEntityName, objectSyncID);
        
        [self.backgroundApplicationContext deleteObject:object];
    }];
}

#pragma mark - TICoreDataFactory Delegate
- (void)coreDataFactory:(TICoreDataFactory *)aFactory encounteredError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Applied Sync Change Sets Factory Error: %@", anError);
}

#pragma mark - Configuration
- (void)configureBackgroundApplicationContextForPrimaryManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self.primaryManagedObjectContext = managedObjectContext;
}

#pragma mark - Initialization and Deallocation
- (id)initWithDelegate:(NSObject<TICDSSynchronizationOperationDelegate> *)aDelegate
{
    return [super initWithDelegate:aDelegate];
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
    
    NSError *error = nil;
    
    NSPersistentStoreCoordinator *persistentStoreCoordinator = _appliedSyncChangeSetsCoreDataFactory.persistentStoreCoordinator;
    for (TICDSSyncTransaction *syncTransaction in self.syncTransactions) {
        if (syncTransaction == self.syncTransaction) {
            continue;
        }
        
        if ([self.fileManager fileExistsAtPath:[syncTransaction.unsavedAppliedSyncChangesFileURL path]]) {
            [persistentStoreCoordinator addPersistentStoreWithType:TICDSSyncChangeSetsCoreDataPersistentStoreType configuration:nil URL:syncTransaction.unsavedAppliedSyncChangesFileURL options:@{ NSReadOnlyPersistentStoreOption:@YES } error:&error];
        }
    }
    
    if (error != nil) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error attempting to add persistent stores to the appliedSyncChangeSets persistent store coordinator. Error: %@", error);
    }
    
    return _appliedSyncChangeSetsCoreDataFactory;
}

- (NSManagedObjectContext *)unsavedAppliedSyncChangeSetsContext
{
    if (_unsavedAppliedSyncChangeSetsContext) {
        return _unsavedAppliedSyncChangeSetsContext;
    }
    
    _unsavedAppliedSyncChangeSetsContext = [self.unsavedAppliedSyncChangeSetsCoreDataFactory managedObjectContext];
    [_unsavedAppliedSyncChangeSetsContext setUndoManager:nil];
    
    return _unsavedAppliedSyncChangeSetsContext;
}

- (TICoreDataFactory *)unsavedAppliedSyncChangeSetsCoreDataFactory
{
    if (_unsavedAppliedSyncChangeSetsCoreDataFactory) {
        return _unsavedAppliedSyncChangeSetsCoreDataFactory;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _unsavedAppliedSyncChangeSetsCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeSetDataModelName];
    [_unsavedAppliedSyncChangeSetsCoreDataFactory setPersistentStoreType:TICDSSyncChangeSetsCoreDataPersistentStoreType];
    [_unsavedAppliedSyncChangeSetsCoreDataFactory setPersistentStoreDataPath:[self.syncTransaction.unsavedAppliedSyncChangesFileURL path]];
    [_unsavedAppliedSyncChangeSetsCoreDataFactory setDelegate:self];
    
    return _unsavedAppliedSyncChangeSetsCoreDataFactory;
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

    if (self.localSyncChangesToMergeURL == nil) {
        return nil;
    }

    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _localSyncChangesToMergeCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeDataModelName];
    [_localSyncChangesToMergeCoreDataFactory setDelegate:self];
    [_localSyncChangesToMergeCoreDataFactory setPersistentStoreType:TICDSSyncChangesCoreDataPersistentStoreType];
    [_localSyncChangesToMergeCoreDataFactory setPersistentStoreDataPath:[self.localSyncChangesToMergeURL path]];

    return _localSyncChangesToMergeCoreDataFactory;
}

- (TICDSSynchronizationOperationManagedObjectContext *)backgroundApplicationContext
{
    if (_backgroundApplicationContext != nil) {
        return _backgroundApplicationContext;
    }

    _backgroundApplicationContext = [[TICDSSynchronizationOperationManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_backgroundApplicationContext performBlockAndWait:^{
        _backgroundApplicationContext.parentContext = self.primaryManagedObjectContext;
        [_backgroundApplicationContext setUndoManager:nil];
    }];

    [[NSNotificationCenter defaultCenter] addObserver:[self delegate] selector:@selector(backgroundManagedObjectContextDidSave:) name:NSManagedObjectContextDidSaveNotification object:_backgroundApplicationContext];

    return _backgroundApplicationContext;
}

@end
