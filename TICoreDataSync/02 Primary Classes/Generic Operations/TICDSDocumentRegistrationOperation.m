//
//  TICDSDocumentRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSDocumentRegistrationOperation () 

- (void)beginCheckForRemoteDocumentDirectory;
- (void)beginRequestWhetherToCreateRemoteDocumentFileStructure;
- (void)continueAfterRequestWhetherToCreateRemoteDocumentFileStructure;
- (void)beginCreatingRemoteDocumentDirectoryStructure;
- (void)beginCreatingDocumentInfoPlist;
- (void)beginCheckForClientDirectoryInDocumentSyncChangesDirectory;
- (void)beginCreatingClientDirectoriesInRemoteDocumentDirectories;

@end


@implementation TICDSDocumentRegistrationOperation

- (void)main
{
    [self beginCheckForRemoteDocumentDirectory];
}

#pragma mark - Checking for Document Directory
- (void)beginCheckForRemoteDocumentDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Checking whether the remote document directory exists");
    
    [self checkWhetherRemoteDocumentDirectoryExists];
}

- (void)discoveredStatusOfRemoteDocumentDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for document directory");
            [self operationDidFailToComplete];
            return;
        
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Document directory exists");
            
            [self beginCheckForClientDirectoryInDocumentSyncChangesDirectory];
            break;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Document directory does not exist, so asking delegate whether to create it");
            
            [self beginRequestWhetherToCreateRemoteDocumentFileStructure];
            break;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherRemoteDocumentDirectoryExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Asking Whether to Create Remote Hierarchy
- (void)beginRequestWhetherToCreateRemoteDocumentFileStructure
{
    if( [NSThread isMainThread] ) {
        [self performSelectorInBackground:@selector(beginRequestWhetherToCreateRemoteDocumentFileStructure) withObject:nil];
        return;
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self setPaused:YES];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Pausing registration as remote document file structure doesn't exist");
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationPausedToFindOutWhetherToCreateRemoteDocumentStructure:) waitUntilDone:NO];
    
    while( [self isPaused] ) {
        sleep(0.2);
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Continuing registration after instruction from delegate");
    
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationResumedFollowingDocumentStructureCreationInstruction:) waitUntilDone:NO];
    
    [pool release];
    [self continueAfterRequestWhetherToCreateRemoteDocumentFileStructure];
}

- (void)continueAfterRequestWhetherToCreateRemoteDocumentFileStructure
{
    if( [self needsMainThread] && ![NSThread isMainThread] ) {
        [self performSelectorOnMainThread:@selector(continueAfterRequestWhetherToCreateRemoteDocumentFileStructure) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if( [self shouldCreateDocumentFileStructure] ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating remote document file structure");
        
        [self beginCreatingRemoteDocumentDirectoryStructure];
    } else {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Cancelling document registration");
        [self operationWasCancelled];
    }
}

#pragma mark - Creating Document Directory
- (void)beginCreatingRemoteDocumentDirectoryStructure
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating remote document directory structure");
    [self createRemoteDocumentDirectoryStructure];
}

- (void)createdRemoteDocumentDirectoryStructureWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create remote document directory structure");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Created remote document directory structure");
    
    [self beginCreatingDocumentInfoPlist];
}

#pragma mark Overridden Method
- (void)createRemoteDocumentDirectoryStructure
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdRemoteDocumentDirectoryStructureWithSuccess:NO];
}

#pragma mark - Creating documentInfo.plist
- (void)beginCreatingDocumentInfoPlist
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating remote documentInfo.plist file");
    
    NSString *pathToFile = [[NSBundle bundleForClass:[self class]] pathForResource:TICDSDocumentInfoPlistFilename ofType:TICDSDocumentInfoPlistExtension];
    
    NSMutableDictionary *documentInfo = [NSMutableDictionary dictionaryWithContentsOfFile:pathToFile];
    
    [documentInfo setValue:[self documentIdentifier] forKey:kTICDSDocumentIdentifier];
    [documentInfo setValue:[self documentDescription] forKey:kTICDSDocumentDescription];
    [documentInfo setValue:[self documentUserInfo] forKey:kTICDSDocumentUserInfo];
    [documentInfo setValue:[self clientIdentifier] forKey:kTICDSOriginalDeviceIdentifier];
    [documentInfo setValue:[self clientDescription] forKey:kTICDSOriginalDeviceDescription];
    
    [self saveRemoteDocumentInfoPlistFromDictionary:documentInfo];
}

- (void)savedRemoteDocumentInfoPlistWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save documentInfo.plist file");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Saved documentInfo.plist file successfully");
    
    [self beginCreatingClientDirectoriesInRemoteDocumentDirectories];
}

#pragma mark Overridden Method
- (void)saveRemoteDocumentInfoPlistFromDictionary:(NSDictionary *)aDictionary
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self savedRemoteDocumentInfoPlistWithSuccess:NO];
}

#pragma mark - Checking for Client Directories in Document Directory
- (void)beginCheckForClientDirectoryInDocumentSyncChangesDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Checking for client's directory inside the document's SyncChanges directory");
    
    [self checkWhetherClientDirectoryExistsInRemoteDocumentSyncChangesDirectory];
}

- (void)discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for status of client's directory");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's directory exists, so document registration is complete");
            
            [self operationDidCompleteSuccessfully];
            return;

        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client's directory does not exist");
            
            [self beginCreatingClientDirectoriesInRemoteDocumentDirectories];
            break;
    }
}

#pragma mark Overridden Methods
- (void)checkWhetherClientDirectoryExistsInRemoteDocumentSyncChangesDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Creating Client Directories
- (void)beginCreatingClientDirectoriesInRemoteDocumentDirectories
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating client's directories inside the document's SyncChanges and SyncCommands directories");
    
    [self createClientDirectoriesInRemoteDocumentDirectories];
}

- (void)createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error creating client's directories");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Created client's directories, so registration is complete");
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Method
- (void)createClientDirectoriesInRemoteDocumentDirectories
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:NO];
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
    [_documentUserInfo release], _documentUserInfo = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize paused = _paused;
@synthesize shouldCreateDocumentFileStructure = _shouldCreateDocumentFileStructure;
@synthesize documentIdentifier = _documentIdentifier;
@synthesize documentDescription = _documentDescription;
@synthesize clientDescription = _clientDescription;
@synthesize documentUserInfo = _documentUserInfo;

@end
