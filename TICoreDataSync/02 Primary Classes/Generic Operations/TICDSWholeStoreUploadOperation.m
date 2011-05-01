//
//  TICDSWholeStoreUploadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSWholeStoreUploadOperation ()

- (void)beginCheckForThisClientWholeStoreDirectory;
- (void)beginCreationOfThisClientWholeStoreDirectory;
- (void)beginUploadOfWholeStoreFile;
- (void)beginUploadOfAppliedSyncChangeSetsFile;
- (void)checkForCompletion;

@end

@implementation TICDSWholeStoreUploadOperation

- (void)main
{
    [self beginCheckForThisClientWholeStoreDirectory];
}

#pragma mark -
#pragma mark Whole Store Directory Check
- (void)beginCheckForThisClientWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Checking whether this client's WholeStore directory exists");
    
    [self checkWhetherThisClientWholeStoreDirectoryExists];
}

- (void)discoveredStatusOfWholeStoreDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    if( status == TICDSRemoteFileStructureExistsResponseTypeError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking whether this client's WholeStore directory exists");
        [self setWholeStoreDirectoryStatus:TICDSOperationPhaseStatusFailure];
        [self setWholeStoreFileUploadStatus:TICDSOperationPhaseStatusFailure];
        [self setAppliedSyncChangeSetsFileUploadStatus:TICDSOperationPhaseStatusFailure];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesExist ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"WholeStore directory exists");
        [self setWholeStoreDirectoryStatus:TICDSOperationPhaseStatusSuccess];
        
        [self beginUploadOfWholeStoreFile];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesNotExist ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"WholeStore directory does not exist");
        
        [self beginCreationOfThisClientWholeStoreDirectory];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Method
- (void)checkWhetherThisClientWholeStoreDirectoryExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfWholeStoreDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark -
#pragma mark Whole Store Directory Creation
- (void)beginCreationOfThisClientWholeStoreDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Creating this client's WholeStore directory");
    
    [self createThisClientWholeStoreDirectory];
}

- (void)createdThisClientWholeStoreDirectorySuccessfully:(BOOL)someSuccess
{
    if( !someSuccess ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create this client's WholeStore directory");
        [self setWholeStoreDirectoryStatus:TICDSOperationPhaseStatusFailure];
        [self setWholeStoreFileUploadStatus:TICDSOperationPhaseStatusFailure];
        [self setAppliedSyncChangeSetsFileUploadStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Created this client's WholeStore directory");
        [self setWholeStoreDirectoryStatus:TICDSOperationPhaseStatusSuccess];
        
        [self beginUploadOfWholeStoreFile];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Method
- (void)createThisClientWholeStoreDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdThisClientWholeStoreDirectorySuccessfully:NO];
}

#pragma mark -
#pragma mark Whole Store File Upload
- (void)beginUploadOfWholeStoreFile
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Uploading whole store file");
    
    [self uploadWholeStoreFile];
}

- (void)uploadedWholeStoreFileWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload whole store file");
        [self setWholeStoreFileUploadStatus:TICDSOperationPhaseStatusFailure];
        [self setAppliedSyncChangeSetsFileUploadStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Successfully uploaded whole store file");
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
#pragma mark Applied Sync Change Sets File Upload
- (void)beginUploadOfAppliedSyncChangeSetsFile
{
    if( ![[self fileManager] fileExistsAtPath:[[self localAppliedSyncChangeSetsFileLocation] path]] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Local applied sync change sets file doesn't exist locally");
        [self setAppliedSyncChangeSetsFileUploadStatus:TICDSOperationPhaseStatusSuccess];
        [self checkForCompletion];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Uploading applied sync change sets file");
    
    [self uploadAppliedSyncChangeSetsFile];
}

- (void)uploadedAppliedSyncChangeSetsFileWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to upload applied sync change sets file");
        [self setAppliedSyncChangeSetsFileUploadStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Successfully uploaded applied sync change sets file");
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
    
    if( [self wholeStoreDirectoryStatus] == TICDSOperationPhaseStatusInProgress || [self wholeStoreFileUploadStatus] == TICDSOperationPhaseStatusInProgress || [self appliedSyncChangeSetsFileUploadStatus] == TICDSOperationPhaseStatusInProgress ) {
        return;
    }
    
    if( [self wholeStoreDirectoryStatus] == TICDSOperationPhaseStatusSuccess && [self wholeStoreFileUploadStatus] == TICDSOperationPhaseStatusSuccess && [self appliedSyncChangeSetsFileUploadStatus] == TICDSOperationPhaseStatusSuccess ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( [self wholeStoreDirectoryStatus] == TICDSOperationPhaseStatusFailure || [self wholeStoreFileUploadStatus] == TICDSOperationPhaseStatusFailure || [self appliedSyncChangeSetsFileUploadStatus] == TICDSOperationPhaseStatusFailure ) {
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
@synthesize wholeStoreDirectoryStatus = _wholeStoreDirectoryStatus;
@synthesize wholeStoreFileUploadStatus = _wholeStoreFileUploadStatus;
@synthesize appliedSyncChangeSetsFileUploadStatus = _appliedSyncChangeSetsFileUploadStatus;

@end
