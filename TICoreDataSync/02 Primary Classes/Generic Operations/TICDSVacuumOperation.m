//
//  TICDSVacuumOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 29/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSVacuumOperation ()

- (void)checkForCompletion;
- (void)beginFindingOutLeastRecentClientSyncDate;
- (void)beginRemovingOldSyncChangeSetFiles;

@end

@implementation TICDSVacuumOperation

- (void)main
{
    [self beginFindingOutLeastRecentClientSyncDate];
}

#pragma mark -
#pragma mark Least Recent Client Sync Date
- (void)beginFindingOutLeastRecentClientSyncDate
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Finding out the date on which the least-recently-synchronized client performed a sync");
    
    [self findOutLeastRecentClientSyncDate];
}

- (void)foundOutLeastRecentClientSyncDate:(NSDate *)aDate
{
    if( !aDate ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to determine the least recent client sync date");
        [self setFindOutLeastRecentClientSyncDateStatus:TICDSOperationPhaseStatusFailure];
        [self setRemoveOldSyncChangeSetFilesStatus:TICDSOperationPhaseStatusFailure];
        [self checkForCompletion];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Least recent client sync date identified as %@", aDate);
    [self setLeastRecentClientSyncDate:aDate];
    [self setFindOutLeastRecentClientSyncDateStatus:TICDSOperationPhaseStatusSuccess];
    
    [self beginRemovingOldSyncChangeSetFiles];
}

#pragma mark Overridden Method
- (void)findOutLeastRecentClientSyncDate
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self foundOutLeastRecentClientSyncDate:nil];
}

#pragma mark -
#pragma mark Remove Old Sync Change Set Files
- (void)beginRemovingOldSyncChangeSetFiles
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Removing unneeded SyncChangeSet files uploaded by this client");
    
    [self removeOldSyncChangeSetFiles];
}

- (void)removedOldSyncChangeSetFilesWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to remove old sync change set files");
        [self setRemoveOldSyncChangeSetFilesStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Removed old sync change set files");
        [self setRemoveOldSyncChangeSetFilesStatus:TICDSOperationPhaseStatusSuccess];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Method
- (void)removeOldSyncChangeSetFiles
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self removedOldSyncChangeSetFilesWithSuccess:NO];
}

#pragma mark -
#pragma mark Completion
- (void)checkForCompletion
{
    if( [self completionInProgress] ) {
        return;
    }
    
    if( [self findOutLeastRecentClientSyncDateStatus] == TICDSOperationPhaseStatusInProgress || [self removeOldSyncChangeSetFilesStatus] == TICDSOperationPhaseStatusInProgress ) {
        return;
    }
    
    if( [self findOutLeastRecentClientSyncDateStatus] == TICDSOperationPhaseStatusSuccess && [self removeOldSyncChangeSetFilesStatus] == TICDSOperationPhaseStatusSuccess ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( [self findOutLeastRecentClientSyncDateStatus] == TICDSOperationPhaseStatusFailure || [self removeOldSyncChangeSetFilesStatus] == TICDSOperationPhaseStatusFailure ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidFailToComplete];
        return;
    }
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_leastRecentClientSyncDate release], _leastRecentClientSyncDate = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize leastRecentClientSyncDate = _leastRecentClientSyncDate;
@synthesize completionInProgress = _completionInProgress;
@synthesize findOutLeastRecentClientSyncDateStatus = _findOutLeastRecentClientSyncDateStatus;
@synthesize removeOldSyncChangeSetFilesStatus = _removeOldSyncChangeSetFilesStatus;

@end
