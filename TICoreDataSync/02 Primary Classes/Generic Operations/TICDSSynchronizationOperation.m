//
//  TICDSSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSSynchronizationOperation ()

- (void)setAllInProgressStatusesToFailure;
- (void)checkForCompletion;
- (void)beginFetchOfListOfClientDeviceIdentifiers;
- (void)beginFetchOfListOfSyncCommandSetIdentifiers;

- (void)increaseNumberOfSyncChangeSetIdentifierArraysToFetch;
- (void)increaseNumberOfSyncChangeSetIdentifierArraysFetched;
- (void)increaseNumberOfSyncChangeSetIdentifierArraysThatFailedToFetch;
- (void)beginFetchOfListOfSyncChangeSetIdentifiers;
- (void)addUnappliedSyncChangeSetIdentifiersFromAvailableSyncChangeSetIdentifiers:(NSArray *)changeSetIdentifiers;
- (BOOL)syncChangeSetHasBeenAppliedWithIdentifier:(NSString *)anIdentifier;

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
    [self setOtherSynchronizedClientDeviceSyncChangeSetIdentifiers:[NSMutableArray arrayWithCapacity:50]];
    
    for( NSString *eachClientIdentifier in [self otherSynchronizedClientDeviceIdentifiers] ) {
        [self buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:eachClientIdentifier];
    }
    
    [self checkForCompletion];
}

- (void)builtArrayOfClientSyncChangeSetIdentifiers:(NSArray *)anArray forClientIdentifier:(NSString *)anIdentifier
{
    if( !anArray ) {
        [self increaseNumberOfSyncChangeSetIdentifierArraysThatFailedToFetch];
    } else {
        [self increaseNumberOfSyncChangeSetIdentifierArraysFetched];
        [self addUnappliedSyncChangeSetIdentifiersFromAvailableSyncChangeSetIdentifiers:anArray];
    }
    
    if( [self numberOfSyncChangeSetIDArraysToFetch] == [self numberOfSyncChangeSetIDArraysFetched] ) {
        [self setFetchArrayOfSyncChangeSetIDsStatus:TICDSOperationPhaseStatusSuccess];
        
        assert(nil);
    } else if( [self numberOfSyncChangeSetIDArraysToFetch] == [self numberOfSyncChangeSetIDArraysFetched] + [self numberOfSyncChangeSetIDArraysThatFailedToFetch] ) {
        [self setAllInProgressStatusesToFailure];
        
        [self checkForCompletion];
    }
}

- (void)addUnappliedSyncChangeSetIdentifiersFromAvailableSyncChangeSetIdentifiers:(NSArray *)changeSetIdentifiers
{
    for( NSString *eachIdentifier in changeSetIdentifiers ) {
        if( [self syncChangeSetHasBeenAppliedWithIdentifier:eachIdentifier] ) {
            continue;
        }
        
        [[self otherSynchronizedClientDeviceSyncChangeSetIdentifiers] addObject:eachIdentifier];
    }
}

- (BOOL)syncChangeSetHasBeenAppliedWithIdentifier:(NSString *)anIdentifier
{
    return NO;
}

#pragma mark Overridden Method
- (void)buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:(NSString *)anIdentifier
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self builtArrayOfClientSyncChangeSetIdentifiers:nil forClientIdentifier:anIdentifier];
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
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_localSyncChangesToMergeLocation release], _localSyncChangesToMergeLocation = nil;
    [_appliedSyncChangeSetsFileLocation release], _appliedSyncChangeSetsFileLocation = nil;
    [_otherSynchronizedClientDeviceIdentifiers release], _otherSynchronizedClientDeviceIdentifiers = nil;
    [_otherSynchronizedClientDeviceSyncChangeSetIdentifiers release], _otherSynchronizedClientDeviceSyncChangeSetIdentifiers = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize localSyncChangesToMergeLocation = _localSyncChangesToMergeLocation;
@synthesize appliedSyncChangeSetsFileLocation = _appliedSyncChangeSetsFileLocation;
@synthesize otherSynchronizedClientDeviceIdentifiers = _otherSynchronizedClientDeviceIdentifiers;
@synthesize otherSynchronizedClientDeviceSyncChangeSetIdentifiers = _otherSynchronizedClientDeviceSyncChangeSetIdentifiers;
@synthesize completionInProgress = _completionInProgress;
@synthesize fetchArrayOfClientDeviceIDsStatus = _fetchArrayOfClientDeviceIDsStatus;
@synthesize fetchArrayOfSyncCommandSetIDsStatus = _fetchArrayOfSyncCommandSetIDsStatus;

@synthesize numberOfSyncChangeSetIDArraysToFetch = _numberOfSyncChangeSetIDArraysToFetch;
@synthesize numberOfSyncChangeSetIDArraysFetched = _numberOfSyncChangeSetIDArraysFetched;
@synthesize numberOfSyncChangeSetIDArraysThatFailedToFetch = _numberOfSyncChangeSetIDArraysThatFailedToFetch;
@synthesize fetchArrayOfSyncChangeSetIDsStatus = _fetchArrayOfSyncChangeSetIDsStatus;

@synthesize fetchUnappliedSyncChangeSetsStatus = _fetchUnappliedSyncChangeSetsStatus;

@synthesize uploadLocalSyncCommandSetStatus = _uploadLocalSyncCommandSetStatus;
@synthesize uploadLocalSyncChangeSetStatus = _uploadLocalSyncChangeSetStatus;

@end
