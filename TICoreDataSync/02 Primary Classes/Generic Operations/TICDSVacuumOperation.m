//
//  TICDSVacuumOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 29/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSVacuumOperation ()

- (void)beginFindingOutDateOfOldestWholeStoreFile;
- (void)beginFindingOutLeastRecentClientSyncDate;
- (void)beginRemovingOldSyncChangeSetFiles;

@end

@implementation TICDSVacuumOperation

- (void)main
{
    [self beginFindingOutDateOfOldestWholeStoreFile];
}

#pragma mark - Checking Oldest WholeStore File Date
- (void)beginFindingOutDateOfOldestWholeStoreFile
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finding out the modification date of the oldest `WholeStore` file.");
    
    [self findOutDateOfOldestWholeStore];
}

- (void)foundOutDateOfOldestWholeStoreFile:(NSDate *)aDate
{
    if( !aDate ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to determine the least recent whole store date");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Oldest whole store modification date identified as: %@", aDate);
    [self setEarliestDateForFilesToKeep:aDate];
    
    [self beginFindingOutLeastRecentClientSyncDate];
}

#pragma mark Overridden Method
- (void)findOutDateOfOldestWholeStore
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self foundOutDateOfOldestWholeStoreFile:nil];
}

#pragma mark - Checking Least Recent Client Sync Date
- (void)beginFindingOutLeastRecentClientSyncDate
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Finding out the date on which the least-recently-synchronized client performed a sync");
    
    [self findOutLeastRecentClientSyncDate];
}

- (void)foundOutLeastRecentClientSyncDate:(NSDate *)aDate
{
    if( !aDate ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to determine the least recent client sync date");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Least recent client sync date identified as %@", aDate);
    
    if( [[self earliestDateForFilesToKeep] compare:aDate] == NSOrderedDescending ) {
        [self setEarliestDateForFilesToKeep:aDate];
    }
    
    [self beginRemovingOldSyncChangeSetFiles];
}

#pragma mark Overridden Method
- (void)findOutLeastRecentClientSyncDate
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self foundOutLeastRecentClientSyncDate:nil];
}

#pragma mark - Remove Old Sync Change Set Files
- (void)beginRemovingOldSyncChangeSetFiles
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Removing unneeded SyncChangeSet files uploaded by this client");
    
    [self removeOldSyncChangeSetFiles];
}

- (void)removedOldSyncChangeSetFilesWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to remove old sync change set files");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Removed old sync change set files");
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)removeOldSyncChangeSetFiles
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self removedOldSyncChangeSetFilesWithSuccess:NO];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _earliestDateForFilesToKeep = nil;
    
}

#pragma mark - Properties
@synthesize earliestDateForFilesToKeep = _earliestDateForFilesToKeep;

@end
