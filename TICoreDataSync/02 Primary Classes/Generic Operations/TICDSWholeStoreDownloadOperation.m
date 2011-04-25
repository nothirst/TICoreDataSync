//
//  TICDSWholeStoreDownloadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSWholeStoreDownloadOperation ()

- (void)checkForCompletion;
- (void)beginDownloadOfWholeStoreFile;
- (void)beginDownloadOfAppliedSyncChangeSetsFile;

@end


@implementation TICDSWholeStoreDownloadOperation

- (void)main
{
    [self beginDownloadOfWholeStoreFile];
}

#pragma mark -
#pragma mark Whole Store File Download
- (void)beginDownloadOfWholeStoreFile
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Downloading whole store file");
    
    [self downloadWholeStoreFile];
}

- (void)downloadedWholeStoreFileWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to download whole store file");
        [self setWholeStoreFileDownloadStatus:TICDSOperationPhaseStatusFailure];
        [self setAppliedSyncChangeSetsFileDownloadStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Successfully downloaded whole store file");
        [self setWholeStoreFileDownloadStatus:TICDSOperationPhaseStatusSuccess];
        
        [self beginDownloadOfAppliedSyncChangeSetsFile];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Method
- (void)downloadWholeStoreFile
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self downloadedWholeStoreFileWithSuccess:NO];
}

#pragma mark -
#pragma mark Applied Sync Change Sets File Download
- (void)beginDownloadOfAppliedSyncChangeSetsFile
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Downloading applied sync change sets file");
    
    [self downloadAppliedSyncChangeSetsFile];
}

- (void)downloadedAppliedSyncChangeSetsFileWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to download applied sync change sets file");
        [self setAppliedSyncChangeSetsFileDownloadStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Successfully downloaded applied sync change sets file");
        [self setAppliedSyncChangeSetsFileDownloadStatus:TICDSOperationPhaseStatusSuccess];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Method
- (void)downloadAppliedSyncChangeSetsFile
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self downloadedAppliedSyncChangeSetsFileWithSuccess:NO];
}

#pragma mark -
#pragma mark Completion
- (void)checkForCompletion
{
    if( [self completionInProgress] ) {
        return;
    }
    
    if( [self wholeStoreFileDownloadStatus] == TICDSOperationPhaseStatusInProgress || [self appliedSyncChangeSetsFileDownloadStatus] == TICDSOperationPhaseStatusInProgress ) {
        return;
    }
    
    if( [self wholeStoreFileDownloadStatus] == TICDSOperationPhaseStatusSuccess && [self appliedSyncChangeSetsFileDownloadStatus] == TICDSOperationPhaseStatusSuccess ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( [self wholeStoreFileDownloadStatus] == TICDSOperationPhaseStatusFailure || [self appliedSyncChangeSetsFileDownloadStatus] == TICDSOperationPhaseStatusFailure ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidFailToComplete];
        return;
    }
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_localWholeStoreFileLocation release], _localWholeStoreFileLocation = nil;
    [_localAppliedSyncChangeSetsFileLocation release], _localAppliedSyncChangeSetsFileLocation = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize localWholeStoreFileLocation = _localWholeStoreFileLocation;
@synthesize localAppliedSyncChangeSetsFileLocation = _localAppliedSyncChangeSetsFileLocation;
@synthesize completionInProgress = _completionInProgress;
@synthesize wholeStoreFileDownloadStatus = _wholeStoreFileDownloadStatus;
@synthesize appliedSyncChangeSetsFileDownloadStatus = _appliedSyncChangeSetsFileDownloadStatus;

@end
