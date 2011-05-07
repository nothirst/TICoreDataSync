//
//  TICDSApplicationRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 21/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@interface TICDSApplicationRegistrationOperation ()

- (void)beginCheckForRemoteGlobalAppDirectory;
- (void)beginRequestWhetherToEnableEncryption;
- (void)continueAfterRequestWhetherToEnableEncryption;
- (void)beginCreatingRemoteGlobalAppDirectoryStructure;
- (void)beginCopyingReadMeToGlobalAppDirectory;
- (void)beginCheckForSaltFile;
- (void)beginSavingSaltDataIfNecessary;
- (void)beginFetchOfSaltFileData;
- (void)beginRequestForEncryptionPassword;
- (void)continueAfterRequestForEncryptionPassword;
- (void)beginTestForCorrectPassword;

- (void)beginCheckForRemoteClientDeviceDirectory;
- (void)beginCreatingRemoteClientDeviceDirectory;
- (void)beginCreatingDeviceInfoFile;

@end

@implementation TICDSApplicationRegistrationOperation

- (void)main
{
    [self beginCheckForRemoteGlobalAppDirectory];
}

#pragma mark -
#pragma mark Global App Directory
- (void)beginCheckForRemoteGlobalAppDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Checking whether the global app directory exists");
    
    [self checkWhetherRemoteGlobalAppDirectoryExists];
}

- (void)discoveredStatusOfRemoteGlobalAppDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    if( status == TICDSRemoteFileStructureExistsResponseTypeError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for global app directory");
        [self operationDidFailToComplete];
        return;
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesExist ) {
        TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Global App directory exists");
        [self beginCheckForSaltFile];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesNotExist ) {
        
        TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Remote app directory doesn't exist so asking delegate whether we should create it");
        [self beginRequestWhetherToEnableEncryption];
    }
}

#pragma mark Creating App Directory Structure
- (void)beginCreatingRemoteGlobalAppDirectoryStructure
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating remote global app directory structure");
    [self createRemoteGlobalAppDirectoryStructure];
}

- (void)createdRemoteGlobalAppDirectoryStructureWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create global app directory structure");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Created Remote global app directory structure");
        
    [self beginCopyingReadMeToGlobalAppDirectory];
}

#pragma mark ReadMe.txt File
- (void)beginCopyingReadMeToGlobalAppDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating ReadMe.txt in root of global app directory structure");
    
    NSString *pathToFile = [[NSBundle bundleForClass:[self class]] pathForResource:@"ReadMe" ofType:@"txt"];
    
    [self copyReadMeTxtFileToRootOfGlobalAppDirectoryFromPath:pathToFile];
}

- (void)copiedReadMeTxtFileToRootOfGlobalAppDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to copy ReadMe.txt file");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Copied ReadMe.txt file");
    
    [self beginSavingSaltDataIfNecessary];
}

#pragma mark Overridden Methods
- (void)checkWhetherRemoteGlobalAppDirectoryExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteGlobalAppDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteGlobalAppDirectoryStructure
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdRemoteGlobalAppDirectoryStructureWithSuccess:NO];
}

- (void)copyReadMeTxtFileToRootOfGlobalAppDirectoryFromPath:(NSString *)aPath
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self copiedReadMeTxtFileToRootOfGlobalAppDirectoryWithSuccess:NO];
}

#pragma mark -
#pragma mark Encryption
- (void)beginRequestWhetherToEnableEncryption
{
    if( [NSThread isMainThread] ) {
        [self performSelectorInBackground:@selector(beginRequestWhetherToEnableEncryption) withObject:nil];
        return;
    }
    
    [self setPaused:YES];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Pausing registration as this is the first time this application has been registered");
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationPausedToFindOutWhetherToEnableEncryption:) waitUntilDone:NO];
    
    while( [self isPaused] ) {
        sleep(0.2);
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Continuing application registration after instruction from delegate");
    
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationResumedFollowingEncryptionInstruction:) waitUntilDone:NO];
    
    [self continueAfterRequestWhetherToEnableEncryption];
}

- (void)continueAfterRequestWhetherToEnableEncryption
{
    if( [self needsMainThread] && ![NSThread isMainThread] ) {
        [self performSelectorOnMainThread:@selector(continueAfterRequestWhetherToEnableEncryption) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if( [self isCancelled] ) {
        [self operationWasCancelled];
        return;
    }
    
    [self beginCreatingRemoteGlobalAppDirectoryStructure];
}

#pragma mark Existing Encryption Password
- (void)beginRequestForEncryptionPassword
{
    if( [NSThread isMainThread] ) {
        [self performSelectorInBackground:@selector(beginRequestForEncryptionPassword) withObject:nil];
        return;
    }
    
    [self setPaused:YES];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Pausing registration because an encryption password is needed");
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationPausedToRequestEncryptionPassword:) waitUntilDone:NO];
    
    while( [self isPaused] ) {
        sleep(0.2);
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Continuing application registration after determining encryption password");
    
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationResumedFollowingPasswordProvision:) waitUntilDone:NO];
    
    [self continueAfterRequestForEncryptionPassword];
}

- (void)continueAfterRequestForEncryptionPassword
{
    if( [self needsMainThread] && ![NSThread isMainThread] ) {
        [self performSelectorOnMainThread:@selector(continueAfterRequestForEncryptionPassword) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if( [self isCancelled] ) {
        [self operationWasCancelled];
        return;
    }
    
    [self beginTestForCorrectPassword];
}

#pragma mark Password Testing
- (void)beginTestForCorrectPassword
{
    // Assume password is correct...
    
    [self beginCheckForRemoteClientDeviceDirectory];
}

#pragma mark -
#pragma mark Salt File Existence
- (void)beginCheckForSaltFile
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking for salt file");
    
    [self checkWhetherSaltFileExists];
}

- (void)discoveredStatusOfSaltFile:(TICDSRemoteFileStructureExistsResponseType)status
{
    if( status == TICDSRemoteFileStructureExistsResponseTypeError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to check for salt file");
        [self operationDidFailToComplete];
        return;
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesExist ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Salt file exists");
        
        [self beginFetchOfSaltFileData];
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesNotExist ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Salt file does not exist");
        
        [self setShouldUseEncryption:NO];
        
        [self beginCheckForRemoteClientDeviceDirectory];
    }
}

#pragma mark Salt File Fetch
- (void)beginFetchOfSaltFileData
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Fetching salt data");
    
    [self fetchSaltData];
}

- (void)fetchedSaltData:(NSData *)saltData
{
    if( !saltData ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error fetching salt data");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched salt data");
    
    [self setShouldUseEncryption:YES];
    
    [self beginRequestForEncryptionPassword];
}

#pragma mark Saving Salt File
- (void)beginSavingSaltDataIfNecessary
{
    if( ![self shouldUseEncryption] ) {
        [self beginCreatingRemoteClientDeviceDirectory];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Using encryption");
    NSData *saltData = [NSKeyedArchiver archivedDataWithRootObject:@"HELLOTHISISMYSALT"];
    // NSData *saltData = [self setEncryptor:[FZAEncryptor encryptorWithPassword:[self password] salt:nil]];
    
    [self saveSaltDataToRemote:saltData];
}

- (void)savedSaltDataToRootOfGlobalAppDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save salt file");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Saved salt file");
    
    [self beginCreatingRemoteClientDeviceDirectory];
}

#pragma mark Overridden Methods
- (void)checkWhetherSaltFileExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfSaltFile:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)fetchSaltData
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedSaltData:nil];
}

- (void)saveSaltDataToRemote:(NSData *)saltData
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self savedSaltDataToRootOfGlobalAppDirectoryWithSuccess:NO];
}

#pragma mark -
#pragma mark Client Device Directory and Info
- (void)beginCheckForRemoteClientDeviceDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Checking for remote client device directory");
    
    [self checkWhetherRemoteClientDeviceDirectoryExists];
}

- (void)discoveredStatusOfRemoteClientDeviceDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    if( status == TICDSRemoteFileStructureExistsResponseTypeError ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for remote client device directory");
        [self operationDidFailToComplete];
        return;
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesExist ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Client Device Directory exists!");
        [self operationDidCompleteSuccessfully];
        return;
    } else if( status == TICDSRemoteFileStructureExistsResponseTypeDoesNotExist ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Client Device Directory does not exist");
        
        [self beginCreatingRemoteClientDeviceDirectory];
    }
}

#pragma Directory Creation
- (void)beginCreatingRemoteClientDeviceDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating client device directory");
    
    [self createRemoteClientDeviceDirectory];
}

- (void)createdRemoteClientDeviceDirectoryWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to create remote client device directory");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Created remote client device directory");
    [self beginCreatingDeviceInfoFile];
}

#pragma Client deviceInfo.plist File
- (void)beginCreatingDeviceInfoFile
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Creating deviceInfo.plist");
    
    NSString *pathToFile = [[NSBundle bundleForClass:[self class]] pathForResource:TICDSDeviceInfoPlistFilename ofType:TICDSDeviceInfoPlistExtension];
    
    NSMutableDictionary *deviceInfo = [NSMutableDictionary dictionaryWithContentsOfFile:pathToFile];
    
    [deviceInfo setValue:[self clientDescription] forKey:kTICDSClientDeviceDescription];
    [deviceInfo setValue:[self clientIdentifier] forKey:kTICDSClientDeviceIdentifier];
    [deviceInfo setValue:[self applicationUserInfo] forKey:kTICDSClientDeviceUserInfo];
    
    [self saveRemoteClientDeviceInfoPlistFromDictionary:deviceInfo];
}

- (void)savedRemoteClientDeviceInfoPlistWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save deviceInfo.plist");
        [self operationDidFailToComplete];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Saved deviceInfo.plist");
    
    [self operationDidCompleteSuccessfully];
}

#pragma mark Overridden Methods
- (void)checkWhetherRemoteClientDeviceDirectoryExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteClientDeviceDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

- (void)createRemoteClientDeviceDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdRemoteClientDeviceDirectoryWithSuccess:NO];
}

- (void)saveRemoteClientDeviceInfoPlistFromDictionary:(NSDictionary *)aDictionary
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self savedRemoteClientDeviceInfoPlistWithSuccess:NO];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (id)initWithDelegate:(NSObject<TICDSApplicationRegistrationOperationDelegate> *)aDelegate
{
    return [super initWithDelegate:aDelegate];
}

- (void)dealloc
{
    [_appIdentifier release], _appIdentifier = nil;
    [_clientDescription release], _clientDescription = nil;
    [_applicationUserInfo release], _applicationUserInfo = nil;
    [_password release], _password = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize appIdentifier = _appIdentifier;
@synthesize clientDescription = _clientDescription;
@synthesize applicationUserInfo = _applicationUserInfo;
@synthesize paused = _paused;
@synthesize shouldUseEncryption = _shouldUseEncryption;
@synthesize password = _password;

@end
