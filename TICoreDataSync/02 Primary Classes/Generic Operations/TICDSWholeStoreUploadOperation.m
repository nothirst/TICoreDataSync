//
//  TICDSWholeStoreUploadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSWholeStoreUploadOperation ()

- (void)beginUploadOfWholeStoreFile;
- (void)beginUploadOfAppliedSyncChangeSetsFile;
- (void)checkForCompletion;

@end

@implementation TICDSWholeStoreUploadOperation

- (void)main
{
    [self beginUploadOfWholeStoreFile];
}

#pragma mark -
#pragma mark Whole Store File Upload
- (void)beginUploadOfWholeStoreFile
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Uploading whole store file");
    
    [self uploadWholeStoreFile];
}

- (void)uploadedWholeStoreFileWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload whole store file");
        [self setWholeStoreFileUploadStatus:TICDSOperationPhaseStatusFailure];
        [self setAppliedSyncChangeSetsFileUploadStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Successfully uploaded whole store file");
        [self setWholeStoreFileUploadStatus:TICDSOperationPhaseStatusSuccess];
        
        [self beginUploadOfAppliedSyncChangeSetsFile];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Method
- (void)uploadWholeStoreFile
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self uploadedWholeStoreFileWithSuccess:NO];
}

#pragma mark -
#pragma mark Applied Sync Change Sets Upload
- (void)beginUploadOfAppliedSyncChangeSetsFile
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Uploading applied sync change sets file");
    
    [self uploadAppliedSyncChangeSetsFile];
}

- (void)uploadedAppliedSyncChangeSetsFileWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload applied sync change sets file");
        [self setAppliedSyncChangeSetsFileUploadStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Successfully uploaded applied sync change sets file");
        [self setAppliedSyncChangeSetsFileUploadStatus:TICDSOperationPhaseStatusSuccess];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Method
- (void)uploadAppliedSyncChangeSetsFile
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self uploadedAppliedSyncChangeSetsFileWithSuccess:NO];
}

#pragma mark -
#pragma mark Completion
- (void)checkForCompletion
{
    if( [self completionInProgress] ) {
        return;
    }
    
    if( [self wholeStoreFileUploadStatus] == TICDSOperationPhaseStatusInProgress || [self appliedSyncChangeSetsFileUploadStatus] == TICDSOperationPhaseStatusInProgress ) {
        return;
    }
    
    if( [self wholeStoreFileUploadStatus] == TICDSOperationPhaseStatusSuccess && [self appliedSyncChangeSetsFileUploadStatus] == TICDSOperationPhaseStatusSuccess ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( [self wholeStoreFileUploadStatus] == TICDSOperationPhaseStatusFailure || [self appliedSyncChangeSetsFileUploadStatus] == TICDSOperationPhaseStatusFailure ) {
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
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize localWholeStoreFileLocation = _localWholeStoreFileLocation;
@synthesize completionInProgress = _completionInProgress;
@synthesize wholeStoreFileUploadStatus = _wholeStoreFileUploadStatus;
@synthesize appliedSyncChangeSetsFileUploadStatus = _appliedSyncChangeSetsFileUploadStatus;

@end
