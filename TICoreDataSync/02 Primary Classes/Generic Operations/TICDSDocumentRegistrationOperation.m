//
//  TICDSDocumentRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSDocumentRegistrationOperation () 

- (void)beginCheckForDocumentFileStructure;
- (void)beginRequestWhetherToCreateRemoteFileStructure;
- (void)continueAfterRequestWhetherToCreateRemoteFileStructure;
- (void)beginCheckForDocumentClientDeviceFileStructure;
- (void)checkForCompletion;

@end


@implementation TICDSDocumentRegistrationOperation

- (void)main
{
    [self beginCheckForDocumentFileStructure];
}

#pragma mark -
#pragma mark Document File Structure
- (void)beginCheckForDocumentFileStructure
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Checking whether document file structure exists");
    [self checkWhetherRemoteDocumentFileStructureExists];    
}

- (void)discoveredStatusOfRemoteDocumentFileStructure:(TICDSRemoteFileStructureExistsResponseType)status
{
    if( status == TICDSRemoteFileStructureExistsResponseTypeError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for remote document file structure");
        [self setDocumentFileStructureStatus:TICDSOperationPhaseStatusFailure];
        [self setDocumentClientDeviceFileStructureStatus:TICDSOperationPhaseStatusFailure];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesExist ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Remote document file structure exists");
        [self setDocumentFileStructureStatus:TICDSOperationPhaseStatusSuccess];
        
        [self beginCheckForDocumentClientDeviceFileStructure];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesNotExist ) {
        
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Remote document file structure doesn't exist so asking delegate whether we should create it");
        [self beginRequestWhetherToCreateRemoteFileStructure];
    }
    
    [self checkForCompletion];
}

- (void)beginRequestWhetherToCreateRemoteFileStructure
{
    if( [NSThread isMainThread] ) {
        [self performSelectorInBackground:@selector(beginRequestWhetherToCreateRemoteFileStructure) withObject:nil];
        return;
    }
    
    [self setPaused:YES];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Pausing registration as remote document file structure doesn't exist");
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationPausedToFindOutWhetherToCreateRemoteDocumentStructure:) waitUntilDone:NO];
    
    while( [self isPaused] ) {
        sleep(0.2);
    }
    
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationResumedFollowingDocumentStructureCreationInstruction:) waitUntilDone:NO];
    
    [self continueAfterRequestWhetherToCreateRemoteFileStructure];
}

- (void)continueAfterRequestWhetherToCreateRemoteFileStructure
{
    if( [self needsMainThread] && ![NSThread isMainThread] ) {
        [self performSelectorOnMainThread:@selector(continueAfterRequestWhetherToCreateRemoteFileStructure) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if( [self shouldCreateDocumentFileStructure] ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Creating remote document file structure");
        
        [self createRemoteDocumentFileStructure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Cancelling document registration");
        [self operationWasCancelled];
    }
}

- (void)createdRemoteDocumentFileStructureWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Failed to create remote document file structure");
        [self setDocumentFileStructureStatus:TICDSOperationPhaseStatusFailure];
        [self setDocumentClientDeviceFileStructureStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Successfully created remote document file structure");
        [self setDocumentFileStructureStatus:TICDSOperationPhaseStatusSuccess];
        
        [self beginCheckForDocumentClientDeviceFileStructure];
    } 
    
    [self checkForCompletion];
}

#pragma mark Overridden Methods
- (void)checkWhetherRemoteDocumentFileStructureExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteDocumentFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteDocumentFileStructure
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdRemoteDocumentFileStructureWithSuccess:NO];
}

#pragma mark -
#pragma mark Client Device File Structure
- (void)beginCheckForDocumentClientDeviceFileStructure
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Starting to check for remote document client device file structure");
    
    [self checkWhetherRemoteDocumentSyncChangesThisClientFileStructureExists];
}

- (void)discoveredStatusOfRemoteDocumentSyncChangesThisClientFileStructure:(TICDSRemoteFileStructureExistsResponseType)status
{
    if( status == TICDSRemoteFileStructureExistsResponseTypeError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for remote document client device file structure");
        [self setDocumentClientDeviceFileStructureStatus:TICDSOperationPhaseStatusFailure];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesExist ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Remote document client device file structure exists");
        [self setDocumentClientDeviceFileStructureStatus:TICDSOperationPhaseStatusSuccess];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesNotExist ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Creating remote document client device file structure");
        
        [self createRemoteDocumentSyncChangesThisClientFileStructure];
    }
    
    [self checkForCompletion];
}

- (void)createdRemoteDocumentSyncChangesThisClientFileStructureWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Failed to create remote document client device file structure");
        [self setDocumentClientDeviceFileStructureStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Successfully created remote document client device file structure");
        [self setDocumentClientDeviceFileStructureStatus:TICDSOperationPhaseStatusSuccess];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Methods
- (void)checkWhetherRemoteDocumentSyncChangesThisClientFileStructureExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteDocumentSyncChangesThisClientFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteDocumentSyncChangesThisClientFileStructure
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdRemoteDocumentSyncChangesThisClientFileStructureWithSuccess:NO];
}

#pragma mark -
#pragma mark Completion
- (void)checkForCompletion
{
    if( [self completionInProgress] ) {
        return;
    }
    
    if( [self documentFileStructureStatus] == TICDSOperationPhaseStatusInProgress || [self documentClientDeviceFileStructureStatus] == TICDSOperationPhaseStatusInProgress ) {
        return;
    }
    
    if( [self documentFileStructureStatus] == TICDSOperationPhaseStatusSuccess && [self documentClientDeviceFileStructureStatus] == TICDSOperationPhaseStatusSuccess ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( [self documentFileStructureStatus] == TICDSOperationPhaseStatusFailure || [self documentClientDeviceFileStructureStatus] == TICDSOperationPhaseStatusFailure ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidFailToComplete];
        return;
    }
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)initWithDelegate:(NSObject<TICDSDocumentRegistrationOperationDelegate> *)aDelegate
{
    return [super initWithDelegate:aDelegate];
}

- (void)dealloc
{
    [_documentIdentifier release], _documentIdentifier = nil;
    [_documentDescription release], _documentDescription = nil;
    [_clientDescription release], _clientDescription = nil;
    [_userInfo release], _userInfo = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize paused = _paused;
@synthesize shouldCreateDocumentFileStructure = _shouldCreateDocumentFileStructure;
@synthesize documentIdentifier = _documentIdentifier;
@synthesize documentDescription = _documentDescription;
@synthesize clientDescription = _clientDescription;
@synthesize userInfo = _userInfo;
@synthesize completionInProgress = _completionInProgress;
@synthesize documentFileStructureStatus = _documentFileStructureStatus;
@synthesize documentClientDeviceFileStructureStatus = _documentClientDeviceFileStructureStatus;

@end
