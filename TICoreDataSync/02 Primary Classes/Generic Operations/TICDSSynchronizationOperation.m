//
//  TICDSSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSSynchronizationOperation ()

- (void)checkForCompletion;
- (void)beginFetchOfListOfClientDeviceIdentifiers;
- (void)beginFetchOfListOfSyncCommandSetIdentifiers;
- (void)beginFetchOfListOfSyncChangeSetIdentifiers;

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
        [self setFetchArrayOfClientDeviceIDsStatus:TICDSOperationPhaseStatusFailure];
        [self setFetchArrayOfSyncCommandSetIDsStatus:TICDSOperationPhaseStatusFailure];
        // TODO: Add other phases that are effectively failed
        
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
    
    assert(nil);
}

#pragma mark -
#pragma mark LIST OF SYNC CHANGE SETS
- (void)beginFetchOfListOfSyncChangeSetIdentifiers
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Starting to fetch list of SyncChangeSet identifiers");
    
    if( [[self otherSynchronizedClientDeviceIdentifiers] count] < 1 ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No other clients are synchronizing with this document, so skipping to uploading SyncCommands");
        [self setFetchArrayOfSyncChangeSetIDsStatus:TICDSOperationPhaseStatusSuccess];
        assert(nil);
        return;
    }
    
    assert(nil);
}

#pragma mark -
#pragma mark Completion
- (void)checkForCompletion
{
    if( [self completionInProgress] ) {
        return;
    }
    
    if( [self fetchArrayOfClientDeviceIDsStatus] == TICDSOperationPhaseStatusInProgress || [self fetchArrayOfSyncCommandSetIDsStatus] == TICDSOperationPhaseStatusInProgress || [self fetchArrayOfSyncChangeSetIDsStatus] == TICDSOperationPhaseStatusInProgress ) {
        return;
    }
    
    if( [self fetchArrayOfClientDeviceIDsStatus] == TICDSOperationPhaseStatusSuccess && [self fetchArrayOfSyncCommandSetIDsStatus] == TICDSOperationPhaseStatusSuccess && [self fetchArrayOfSyncChangeSetIDsStatus] == TICDSOperationPhaseStatusSuccess ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( [self fetchArrayOfClientDeviceIDsStatus] == TICDSOperationPhaseStatusFailure || [self fetchArrayOfSyncCommandSetIDsStatus] == TICDSOperationPhaseStatusFailure || [self fetchArrayOfSyncChangeSetIDsStatus] == TICDSOperationPhaseStatusFailure ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidFailToComplete];
        return;
    }
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_otherSynchronizedClientDeviceIdentifiers release], _otherSynchronizedClientDeviceIdentifiers = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize otherSynchronizedClientDeviceIdentifiers = _otherSynchronizedClientDeviceIdentifiers;
@synthesize completionInProgress = _completionInProgress;
@synthesize fetchArrayOfClientDeviceIDsStatus = _fetchArrayOfClientDeviceIDsStatus;
@synthesize fetchArrayOfSyncCommandSetIDsStatus = _fetchArrayOfSyncCommandSetIDsStatus;
@synthesize fetchArrayOfSyncChangeSetIDsStatus = _fetchArrayOfSyncChangeSetIDsStatus;

@end
