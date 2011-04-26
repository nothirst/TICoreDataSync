//
//  TICDSSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSSynchronizationOperation () <TICoreDataFactoryDelegate>

- (void)setAllInProgressStatusesToFailure;
- (void)checkForCompletion;
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

- (void)addUnappliedSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientWithIdentifier:(NSString *)aClientIdentifier;

- (void)beginUploadOfLocalSyncCommands;
- (void)beginUploadOfLocalSyncChanges;

@end

@implementation TICDSSynchronizationOperation

- (void)main
{
    [self beginFetchOfListOfClientDeviceIdentifiers];
}

#pragma mark -
#pragma mark LIST OF DEVICE IDENTIFIERS
- (void)beginFetchOfListOfClientDeviceIdentifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Starting to fetch list of client device identifiers");
    
    [self buildArrayOfClientDeviceIdentifiers];
}

- (void)builtArrayOfClientDeviceIdentifiers:(NSArray *)anArray
{
    if( !anArray ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching list of client device identifiers");
        [self setAllInProgressStatusesToFailure];
        
        [self checkForCompletion];
        return;
    }
    
    [self setFetchArrayOfClientDeviceIDsStatus:TICDSOperationPhaseStatusSuccess];
    
    NSMutableArray *clientIdentifiers = [NSMutableArray arrayWithCapacity:[anArray count]];
    
    for( NSString *eachClientIdentifier in anArray ) {
        if( [eachClientIdentifier isEqualToString:[self clientIdentifier]] ) {
            continue;
        }
        
        [clientIdentifiers addObject:eachClientIdentifier];
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

#pragma mark -
#pragma mark LIST OF SYNC COMMAND SETS
- (void)beginFetchOfListOfSyncCommandSetIdentifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Starting to fetch list of SyncCommandSet identifiers for clients %@", [self otherSynchronizedClientDeviceIdentifiers]);
    
    if( [[self otherSynchronizedClientDeviceIdentifiers] count] < 1 ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No other clients are synchronizing with this document, so skipping to fetch SyncChanges");
        [self setFetchArrayOfSyncCommandSetIDsStatus:TICDSOperationPhaseStatusSuccess];
        [self beginFetchOfListOfSyncChangeSetIdentifiers];
        return;
    }
    
    [self setFetchArrayOfSyncCommandSetIDsStatus:TICDSOperationPhaseStatusSuccess];
    
    // TODO: Fetch of Sync Commands
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"***Not yet implemented*** so 'finished' fetch of local sync commands");
    
    [self beginFetchOfListOfSyncChangeSetIdentifiers];
}

#pragma mark -
#pragma mark LIST OF SYNC CHANGE SETS
- (void)beginFetchOfListOfSyncChangeSetIdentifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Starting to fetch list of SyncChangeSet identifiers");
    
    if( [[self otherSynchronizedClientDeviceIdentifiers] count] < 1 ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No other clients are synchronizing with this document, so skipping to uploading SyncCommands");
        [self setFetchArrayOfSyncChangeSetIDsStatus:TICDSOperationPhaseStatusSuccess];
        [self beginUploadOfLocalSyncCommands];
        return;
    }
    
    [self setNumberOfSyncChangeSetIDArraysToFetch:[[self otherSynchronizedClientDeviceIdentifiers] count]];
    
    [self setOtherSynchronizedClientDeviceSyncChangeSetIdentifiers:[NSMutableDictionary dictionaryWithCapacity:[[self otherSynchronizedClientDeviceIdentifiers] count]]];
    
    for( NSString *eachClientIdentifier in [self otherSynchronizedClientDeviceIdentifiers] ) {
        [self buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:eachClientIdentifier];
    }
    
    [self checkForCompletion];
}

- (void)builtArrayOfClientSyncChangeSetIdentifiers:(NSArray *)anArray forClientIdentifier:(NSString *)aClientIdentifier
{
    if( !anArray ) {
        [self increaseNumberOfSyncChangeSetIdentifierArraysThatFailedToFetch];
    } else {
        [self increaseNumberOfSyncChangeSetIdentifierArraysFetched];
        anArray = [self unappliedSyncChangeSetIdentifiersFromAvailableSyncChangeSetIdentifiers:anArray];
    }
    
    if( [anArray count] > 0 ) {
        [[self otherSynchronizedClientDeviceSyncChangeSetIdentifiers] setValue:anArray forKey:aClientIdentifier];
    }
    
    if( [self numberOfSyncChangeSetIDArraysToFetch] == [self numberOfSyncChangeSetIDArraysFetched] ) {
        [self setFetchArrayOfSyncChangeSetIDsStatus:TICDSOperationPhaseStatusSuccess];
        
        [self beginFetchOfUnappliedSyncChanges];
    } else if( [self numberOfSyncChangeSetIDArraysToFetch] == [self numberOfSyncChangeSetIDArraysFetched] + [self numberOfSyncChangeSetIDArraysThatFailedToFetch] ) {
        [self setAllInProgressStatusesToFailure];
        
        [self checkForCompletion];
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

#pragma mark -
#pragma mark FETCH OF UNAPPLIED SYNC CHANGE SETS
- (void)beginFetchOfUnappliedSyncChanges
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Fetching unapplied sync change sets");
    
    if( [[self otherSynchronizedClientDeviceSyncChangeSetIdentifiers] count] < 1 ) {
        [self setFetchUnappliedSyncChangeSetsStatus:TICDSOperationPhaseStatusSuccess];
        
        // TODO: whatever's next
        assert(nil);
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

- (void)fetchedSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientIdentifier:(NSString *)aClientIdentifier withSuccess:(BOOL)success
{
    if( success ) {
        [self addUnappliedSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientWithIdentifier:aClientIdentifier];
        [self increaseNumberOfUnappliedSyncChangeSetsFetched];
    } else {
        [self increaseNumberOfUnappliedSyncChangeSetsThatFailedToFetch];
    }
    
    if( [self numberOfUnappliedSyncChangeSetsToFetch] == [self numberOfUnappliedSyncChangeSetsFetched] ) {
        [self setFetchUnappliedSyncChangeSetsStatus:TICDSOperationPhaseStatusSuccess];
        
        //TODO: whatever's next
        NSError *anyError = nil;
        BOOL success = [[self unappliedSyncChangeSetsContext] save:&anyError];
        if( !success ) {
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save UnappliedSyncChanges.sqlite file: %@", anyError);
        }
        assert(nil);
    } else if( [self numberOfUnappliedSyncChangeSetsToFetch] == [self numberOfUnappliedSyncChangeSetsFetched] + [self numberOfUnappliedSyncChangeSetsThatFailedToFetch] ) {
        [self setAllInProgressStatusesToFailure];
    }
    [self checkForCompletion];
}

- (void)addUnappliedSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientWithIdentifier:(NSString *)aClientIdentifier
{
    // Check whether it already exists
    NSError *anyError = nil;
    
    TICDSSyncChangeSet *set = [TICDSSyncChangeSet ti_firstObjectMatchingPredicate:[NSPredicate predicateWithFormat:@"syncChangeSetIdentifier == %@", aChangeSetIdentifier] inManagedObjectContext:[self unappliedSyncChangeSetsContext] error:&anyError];
    
    if( set ) {
        return;
    }
    
    if( anyError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to add unapplied sync change set to UnappliedSyncChangeSets.sqlite: %@", anyError);
        return;
    }
    
    set = [TICDSSyncChangeSet syncChangeSetWithIdentifier:aChangeSetIdentifier fromClient:aClientIdentifier creationDate:nil inManagedObjectContext:[self unappliedSyncChangeSetsContext]];
}

#pragma mark Overridden Method
- (void)fetchSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientIdentifier:(NSString *)aClientIdentifier toLocation:(NSURL *)aLocation
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientIdentifier:aClientIdentifier withSuccess:NO];
}

#pragma mark -
#pragma mark UPLOAD OF LOCAL SYNC COMMANDS
- (void)beginUploadOfLocalSyncCommands
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Starting to upload local sync commands");
    
    [self setUploadLocalSyncCommandSetStatus:TICDSOperationPhaseStatusSuccess];
    
    // TODO: Upload of Local Sync Commands
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"***Not yet implemented*** so 'finished' local sync commands");
    
    [self beginUploadOfLocalSyncChanges];
}

#pragma mark -
#pragma mark UPLOAD OF LOCAL SYNC CHANGES
- (void)beginUploadOfLocalSyncChanges
{
    if( ![[self fileManager] fileExistsAtPath:[[self localSyncChangesToMergeLocation] path]] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No local sync changes file to push on this sync");
        [self setUploadLocalSyncChangeSetStatus:TICDSOperationPhaseStatusSuccess];
        [self checkForCompletion];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Renaming sync changes file ready for upload");
    
    NSString *filePath = [[self localSyncChangesToMergeLocation] path];
    filePath = [filePath stringByDeletingLastPathComponent];
    filePath = [filePath stringByAppendingPathComponent:[TICDSUtilities uuidString]];
    filePath = [filePath stringByAppendingPathExtension:TICDSSyncChangeSetFileExtension];
    
    NSError *anyError = nil;
    BOOL success = [[self fileManager] moveItemAtPath:[[self localSyncChangesToMergeLocation] path] toPath:filePath error:&anyError];
    
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to move local sync changes to merge file");
        
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];        
        [self setAllInProgressStatusesToFailure];
        
        [self checkForCompletion];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Starting to upload local sync changes");
    [self uploadLocalSyncChangeSetFileAtLocation:[NSURL fileURLWithPath:filePath]];
}

- (void)uploadedLocalSyncChangeSetFileSuccessfully:(BOOL)success
{
    if( success ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Uploaded local sync changes file");
        [self setUploadLocalSyncChangeSetStatus:TICDSOperationPhaseStatusSuccess];
    } else {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload local sync changes files");
        [self setAllInProgressStatusesToFailure];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Method
- (void)uploadLocalSyncChangeSetFileAtLocation:(NSURL *)aLocation
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self uploadedLocalSyncChangeSetFileSuccessfully:NO];
}

#pragma mark -
#pragma mark Completion
- (void)setAllInProgressStatusesToFailure
{
    if( [self fetchArrayOfClientDeviceIDsStatus] == TICDSOperationPhaseStatusInProgress ) {
        [self setFetchArrayOfClientDeviceIDsStatus:TICDSOperationPhaseStatusFailure];
    }
    
    if( [self fetchArrayOfSyncCommandSetIDsStatus] == TICDSOperationPhaseStatusInProgress ) {
        [self setFetchArrayOfSyncCommandSetIDsStatus:TICDSOperationPhaseStatusFailure];
    }
    
    if( [self fetchArrayOfSyncChangeSetIDsStatus] == TICDSOperationPhaseStatusInProgress ) {
        [self setFetchArrayOfSyncChangeSetIDsStatus:TICDSOperationPhaseStatusFailure];
    }
    
    if( [self fetchUnappliedSyncChangeSetsStatus] == TICDSOperationPhaseStatusInProgress ) {
        [self setFetchUnappliedSyncChangeSetsStatus:TICDSOperationPhaseStatusFailure];
    }
    
    if( [self uploadLocalSyncCommandSetStatus] == TICDSOperationPhaseStatusInProgress ) {
        [self setUploadLocalSyncCommandSetStatus:TICDSOperationPhaseStatusFailure];
    }
    
    if( [self uploadLocalSyncChangeSetStatus] == TICDSOperationPhaseStatusInProgress ) {
        [self setUploadLocalSyncChangeSetStatus:TICDSOperationPhaseStatusFailure];
    }
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

- (void)checkForCompletion
{
    if( [self completionInProgress] ) {
        return;
    }
    
    if( [self fetchArrayOfClientDeviceIDsStatus] == TICDSOperationPhaseStatusInProgress || [self fetchArrayOfSyncCommandSetIDsStatus] == TICDSOperationPhaseStatusInProgress || [self fetchArrayOfSyncChangeSetIDsStatus] == TICDSOperationPhaseStatusInProgress || [self fetchUnappliedSyncChangeSetsStatus] == TICDSOperationPhaseStatusInProgress
       
       || [self uploadLocalSyncCommandSetStatus] == TICDSOperationPhaseStatusInProgress || [self uploadLocalSyncChangeSetStatus] == TICDSOperationPhaseStatusInProgress ) {
        return;
    }
    
    if( [self fetchArrayOfClientDeviceIDsStatus] == TICDSOperationPhaseStatusSuccess && [self fetchArrayOfSyncCommandSetIDsStatus] == TICDSOperationPhaseStatusSuccess && [self fetchArrayOfSyncChangeSetIDsStatus] == TICDSOperationPhaseStatusSuccess && [self fetchUnappliedSyncChangeSetsStatus] == TICDSOperationPhaseStatusSuccess
       
       && [self uploadLocalSyncCommandSetStatus] == TICDSOperationPhaseStatusSuccess && [self uploadLocalSyncChangeSetStatus] == TICDSOperationPhaseStatusSuccess ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( [self fetchArrayOfClientDeviceIDsStatus] == TICDSOperationPhaseStatusFailure || [self fetchArrayOfSyncCommandSetIDsStatus] == TICDSOperationPhaseStatusFailure || [self fetchArrayOfSyncChangeSetIDsStatus] == TICDSOperationPhaseStatusFailure || [self fetchUnappliedSyncChangeSetsStatus] == TICDSOperationPhaseStatusFailure
       
       || [self uploadLocalSyncCommandSetStatus] == TICDSOperationPhaseStatusFailure || [self uploadLocalSyncChangeSetStatus] == TICDSOperationPhaseStatusFailure ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidFailToComplete];
        return;
    }
}

#pragma mark -
#pragma mark TICoreDataFactory Delegate
- (void)coreDataFactory:(TICoreDataFactory *)aFactory encounteredError:(NSError *)anError
{
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Applied Sync Change Sets Factory Error: %@", anError);
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_localSyncChangesToMergeLocation release], _localSyncChangesToMergeLocation = nil;
    [_appliedSyncChangeSetsFileLocation release], _appliedSyncChangeSetsFileLocation = nil;
    [_appliedSyncChangeSetsCoreDataFactory release], _appliedSyncChangeSetsCoreDataFactory = nil;
    [_appliedSyncChangeSetsContext release], _appliedSyncChangeSetsContext = nil;
    [_unappliedSyncChangesDirectoryLocation release], _unappliedSyncChangesDirectoryLocation = nil;
    [_unappliedSyncChangeSetsFileLocation release], _unappliedSyncChangeSetsFileLocation = nil;
    [_unappliedSyncChangeSetsCoreDataFactory release], _unappliedSyncChangeSetsCoreDataFactory = nil;
    [_unappliedSyncChangeSetsContext release], _unappliedSyncChangeSetsContext = nil;

    [_otherSynchronizedClientDeviceIdentifiers release], _otherSynchronizedClientDeviceIdentifiers = nil;
    [_otherSynchronizedClientDeviceSyncChangeSetIdentifiers release], _otherSynchronizedClientDeviceSyncChangeSetIdentifiers = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Lazy Accessors
- (NSManagedObjectContext *)appliedSyncChangeSetsContext
{
    if( _appliedSyncChangeSetsContext ) {
        return _appliedSyncChangeSetsContext;
    }
    
    _appliedSyncChangeSetsContext = [[[self appliedSyncChangeSetsCoreDataFactory] managedObjectContext] retain];
    
    return _appliedSyncChangeSetsContext;
}

- (TICoreDataFactory *)appliedSyncChangeSetsCoreDataFactory
{
    if( _appliedSyncChangeSetsCoreDataFactory ) {
        return _appliedSyncChangeSetsCoreDataFactory;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _appliedSyncChangeSetsCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeSetDataModelName];
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
    
    return _unappliedSyncChangeSetsContext;
}

- (TICoreDataFactory *)unappliedSyncChangeSetsCoreDataFactory
{
    if( _unappliedSyncChangeSetsCoreDataFactory ) {
        return _unappliedSyncChangeSetsCoreDataFactory;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Creating Core Data Factory (TICoreDataFactory)");
    _unappliedSyncChangeSetsCoreDataFactory = [[TICoreDataFactory alloc] initWithMomdName:TICDSSyncChangeSetDataModelName];
    [_unappliedSyncChangeSetsCoreDataFactory setPersistentStoreDataPath:[[self unappliedSyncChangeSetsFileLocation] path]];
    [_unappliedSyncChangeSetsCoreDataFactory setDelegate:self];
    
    return _unappliedSyncChangeSetsCoreDataFactory;
}

#pragma mark -
#pragma mark Properties
@synthesize localSyncChangesToMergeLocation = _localSyncChangesToMergeLocation;
@synthesize appliedSyncChangeSetsFileLocation = _appliedSyncChangeSetsFileLocation;
@synthesize appliedSyncChangeSetsCoreDataFactory = _appliedSyncChangeSetsCoreDataFactory;
@synthesize appliedSyncChangeSetsContext = _appliedSyncChangeSetsContext;
@synthesize unappliedSyncChangesDirectoryLocation = _unappliedSyncChangesDirectoryLocation;
@synthesize unappliedSyncChangeSetsFileLocation = _unappliedSyncChangeSetsFileLocation;
@synthesize unappliedSyncChangeSetsCoreDataFactory = _unappliedSyncChangeSetsCoreDataFactory;
@synthesize unappliedSyncChangeSetsContext = _unappliedSyncChangeSetsContext;

@synthesize otherSynchronizedClientDeviceIdentifiers = _otherSynchronizedClientDeviceIdentifiers;
@synthesize otherSynchronizedClientDeviceSyncChangeSetIdentifiers = _otherSynchronizedClientDeviceSyncChangeSetIdentifiers;
@synthesize completionInProgress = _completionInProgress;
@synthesize fetchArrayOfClientDeviceIDsStatus = _fetchArrayOfClientDeviceIDsStatus;
@synthesize fetchArrayOfSyncCommandSetIDsStatus = _fetchArrayOfSyncCommandSetIDsStatus;

@synthesize numberOfSyncChangeSetIDArraysToFetch = _numberOfSyncChangeSetIDArraysToFetch;
@synthesize numberOfSyncChangeSetIDArraysFetched = _numberOfSyncChangeSetIDArraysFetched;
@synthesize numberOfSyncChangeSetIDArraysThatFailedToFetch = _numberOfSyncChangeSetIDArraysThatFailedToFetch;
@synthesize fetchArrayOfSyncChangeSetIDsStatus = _fetchArrayOfSyncChangeSetIDsStatus;

@synthesize numberOfUnappliedSyncChangeSetsToFetch = _numberOfUnappliedSyncChangeSetsToFetch;
@synthesize numberOfUnappliedSyncChangeSetsFetched = _numberOfUnappliedSyncChangeSetsFetched;
@synthesize numberOfUnappliedSyncChangeSetsThatFailedToFetch = _numberOfUnappliedSyncChangeSetsThatFailedToFetch;
@synthesize fetchUnappliedSyncChangeSetsStatus = _fetchUnappliedSyncChangeSetsStatus;

@synthesize uploadLocalSyncCommandSetStatus = _uploadLocalSyncCommandSetStatus;
@synthesize uploadLocalSyncChangeSetStatus = _uploadLocalSyncChangeSetStatus;

@end
