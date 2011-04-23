//
//  TICDSApplicationRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSApplicationRegistrationOperation ()

- (void)beginCheckForRemoteGlobalAppFileStructure;
- (void)beginCheckForRemoteClientDeviceFileStructure;
- (void)checkForCompletion;

@end

@implementation TICDSApplicationRegistrationOperation

- (void)main
{
    [self beginCheckForRemoteGlobalAppFileStructure];
}

#pragma mark -
#pragma mark Remote Global App File Structure
- (void)beginCheckForRemoteGlobalAppFileStructure
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Starting to check for remote global app file structure");
    
    [self checkWhetherRemoteGlobalAppFileStructureExists];
}

- (void)discoveredStatusOfRemoteGlobalAppFileStructure:(TICDSRemoteFileStructureExistsResponseType)status
{
    if( status == TICDSRemoteFileStructureExistsResponseTypeError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for remote global app file structure");
        [self setGlobalAppFileStructureStatus:TICDSOperationPhaseStatusFailure];
        [self setClientDeviceFileStructureStatus:TICDSOperationPhaseStatusFailure];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesExist ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Remote global app file structure exists");
        [self setGlobalAppFileStructureStatus:TICDSOperationPhaseStatusSuccess];
        
        [self beginCheckForRemoteClientDeviceFileStructure];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesNotExist ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Creating remote global app file structure");
        
        [self createRemoteGlobalAppFileStructure];
        return;
    }
    
    [self checkForCompletion];
}

- (void)createdRemoteGlobalAppFileStructureSuccessfully:(BOOL)someSuccess
{
    if( !someSuccess ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Failed to create remote global app file structure");
        [self setGlobalAppFileStructureStatus:TICDSOperationPhaseStatusFailure];
        [self setClientDeviceFileStructureStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Successfully created remote global app file structure");
        [self setGlobalAppFileStructureStatus:TICDSOperationPhaseStatusSuccess];
        
        [self beginCheckForRemoteClientDeviceFileStructure];
    } 
    
    [self checkForCompletion];
}

#pragma mark Overridden Methods
- (void)checkWhetherRemoteGlobalAppFileStructureExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteGlobalAppFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteGlobalAppFileStructure
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdRemoteGlobalAppFileStructureSuccessfully:NO];
}

#pragma mark -
#pragma mark Remote Client Device File Structure
- (void)beginCheckForRemoteClientDeviceFileStructure
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Starting to check for remote device file structure");
    
    [self checkWhetherRemoteGlobalAppThisClientDeviceFileStructureExists];    
}

- (void)discoveredStatusOfRemoteClientDeviceFileStructure:(TICDSRemoteFileStructureExistsResponseType)status
{
    if( status == TICDSRemoteFileStructureExistsResponseTypeError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for remote client device file structure");
        [self setClientDeviceFileStructureStatus:TICDSOperationPhaseStatusFailure];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesExist ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Remote client device file structure exists");
        [self setClientDeviceFileStructureStatus:TICDSOperationPhaseStatusSuccess];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesNotExist ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Creating remote client device file structure");
        
        [self createRemoteGlobalAppThisClientDeviceFileStructure];
    }
    
    [self checkForCompletion];
}

- (void)createdRemoteClientDeviceFileStructureSuccessfully:(BOOL)someSuccess
{
    if( !someSuccess ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Failed to create remote client device file structure");
        [self setClientDeviceFileStructureStatus:TICDSOperationPhaseStatusFailure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachPhase, @"Successfully created remote client device file structure");
        [self setClientDeviceFileStructureStatus:TICDSOperationPhaseStatusSuccess];
    }
    
    [self checkForCompletion];
}

#pragma mark Overridden Methods

- (void)checkWhetherRemoteGlobalAppThisClientDeviceFileStructureExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteClientDeviceFileStructure:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteGlobalAppThisClientDeviceFileStructure
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdRemoteClientDeviceFileStructureSuccessfully:NO];
}

#pragma mark -
#pragma mark Completion
- (void)checkForCompletion
{
    if( [self completionInProgress] ) {
        return;
    }
    
    if( [self globalAppFileStructureStatus] == TICDSOperationPhaseStatusInProgress || [self clientDeviceFileStructureStatus] == TICDSOperationPhaseStatusInProgress ) {
        return;
    }
    
    if( [self globalAppFileStructureStatus] == TICDSOperationPhaseStatusSuccess && [self clientDeviceFileStructureStatus] == TICDSOperationPhaseStatusSuccess ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidCompleteSuccessfully];
        return;
    }
    
    if( [self globalAppFileStructureStatus] == TICDSOperationPhaseStatusFailure || [self clientDeviceFileStructureStatus] == TICDSOperationPhaseStatusFailure ) {
        [self setCompletionInProgress:YES];
        
        [self operationDidFailToComplete];
        return;
    }
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_appIdentifier release], _appIdentifier = nil;
    [_clientDescription release], _clientDescription = nil;
    [_userInfo release], _userInfo = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize appIdentifier = _appIdentifier;
@synthesize clientDescription = _clientDescription;
@synthesize userInfo = _userInfo;
@synthesize completionInProgress = _completionInProgress;
@synthesize globalAppFileStructureStatus = _globalAppFileStructureStatus;
@synthesize clientDeviceFileStructureStatus = _clientDeviceFileStructureStatus;

@end
