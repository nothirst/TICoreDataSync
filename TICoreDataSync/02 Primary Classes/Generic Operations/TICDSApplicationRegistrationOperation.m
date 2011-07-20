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
- (void)beginSavingSaltData:(NSData *)saltData;
- (void)beginFetchOfSaltFileData;
- (void)beginRequestForEncryptionPassword;
- (void)continueAfterRequestForEncryptionPassword;
- (void)beginSavingPasswordTestData;
- (void)beginTestForCorrectPassword;
- (void)beginCheckForRemoteClientDeviceDirectory;
- (void)beginCreatingRemoteClientDeviceDirectory;
- (void)beginCreatingDeviceInfoFile;
- (void)blitzKeychainItems;
- (void)createCryptorIfNecessary;

@end

@implementation TICDSApplicationRegistrationOperation

- (void)main
{
    [self createCryptorIfNecessary];
    
    [self beginCheckForRemoteGlobalAppDirectory];
}

#pragma mark - Global App Directory Check
- (void)beginCheckForRemoteGlobalAppDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Checking whether the global app directory exists");
    
    [self checkWhetherRemoteGlobalAppDirectoryExists];
}

- (void)discoveredStatusOfRemoteGlobalAppDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for global app directory");
            [self operationDidFailToComplete];
            return;

        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Global App directory exists");
            [self beginCheckForSaltFile];
            break;
        
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Remote app directory doesn't exist so blitzing keychain, then asking delegate whether to create it");
            [self blitzKeychainItems];
            
            [self beginRequestWhetherToEnableEncryption];
            break;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherRemoteGlobalAppDirectoryExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteGlobalAppDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - General Encryption
- (void)beginRequestWhetherToEnableEncryption
{
    if( [NSThread isMainThread] ) {
        [self performSelectorInBackground:@selector(beginRequestWhetherToEnableEncryption) withObject:nil];
        return;
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self setPaused:YES];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Pausing registration as this is the first time this application has been registered");
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationPausedToFindOutWhetherToEnableEncryption:) waitUntilDone:NO];
    
    while( [self isPaused] ) {
        [NSThread sleepForTimeInterval:0.2];
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Continuing application registration after instruction from delegate");
    
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationResumedFollowingEncryptionInstruction:) waitUntilDone:NO];
    
    [pool release];
    
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

#pragma mark - Global App Directory Creation
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

#pragma mark Overridden Method
- (void)createRemoteGlobalAppDirectoryStructure
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdRemoteGlobalAppDirectoryStructureWithSuccess:NO];
}

#pragma mark - Copy ReadMe.txt File
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
    
    if( [self shouldUseEncryption] ) {
        [self createCryptorIfNecessary];
        
        NSData *saltData = [[self cryptor] setPassword:[self password] salt:nil];
        
        [self beginSavingSaltData:saltData];
    } else {
        [self beginCreatingRemoteClientDeviceDirectory];
    }
}

#pragma mark Overridden Method
- (void)copyReadMeTxtFileToRootOfGlobalAppDirectoryFromPath:(NSString *)aPath
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self copiedReadMeTxtFileToRootOfGlobalAppDirectoryWithSuccess:NO];
}

#pragma mark - Saving Salt File
- (void)beginSavingSaltData:(NSData *)saltData
{
    TICDSLog(TICDSLogVerbosityEveryStep, @"Saving salt data to remote");
    
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
    
    [self beginSavingPasswordTestData];
}

#pragma mark Overridden Method
- (void)saveSaltDataToRemote:(NSData *)saltData
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self savedSaltDataToRootOfGlobalAppDirectoryWithSuccess:NO];
}

#pragma mark - Password Test File Creation
- (void)beginSavingPasswordTestData
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Saving password test data");
    
    NSString *testString = [NSString stringWithFormat:@"%@%@", [self appIdentifier], [TICDSUtilities uuidString]];
    
    NSData *testData = [NSKeyedArchiver archivedDataWithRootObject:testString];
    
    [self savePasswordTestData:testData];
}

- (void)savedPasswordTestDataWithSuccess:(BOOL)success
{
    if( !success ) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to save password test data");
        [self operationDidFailToComplete];
        return;
    }
    
    [self beginCreatingRemoteClientDeviceDirectory];
}

#pragma mark Overridden Method
- (void)savePasswordTestData:(NSData *)testData
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self savedPasswordTestDataWithSuccess:NO];
}

#pragma mark - Client Device Directory Creation
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

#pragma mark Overridden Method
- (void)createRemoteClientDeviceDirectory
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self createdRemoteClientDeviceDirectoryWithSuccess:NO];
}

#pragma mark - Client deviceInfo.plist File
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

#pragma mark Overridden Method
- (void)saveRemoteClientDeviceInfoPlistFromDictionary:(NSDictionary *)aDictionary
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self savedRemoteClientDeviceInfoPlistWithSuccess:NO];
}

#pragma mark - Salt File Existence
- (void)beginCheckForSaltFile
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Checking for salt file");
    
    [self checkWhetherSaltFileExists];
}

- (void)discoveredStatusOfSaltFile:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to check for salt file");
            [self operationDidFailToComplete];
            return;

        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Salt file exists");
            
            [self setShouldUseEncryption:YES];
            
            [self beginFetchOfSaltFileData];
            break;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Salt file does not exist");
            
            [self setShouldUseEncryption:NO];
            
            [self beginCheckForRemoteClientDeviceDirectory];
            break;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherSaltFileExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfSaltFile:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Salt File Fetch
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
    
    [self setSaltData:saltData];
    
    [self beginCheckForRemoteClientDeviceDirectory];
}

#pragma mark Overridden Method
- (void)fetchSaltData
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedSaltData:nil];
}

#pragma mark - Check for Client Device Directory
- (void)beginCheckForRemoteClientDeviceDirectory
{
    TICDSLog(TICDSLogVerbosityStartAndEndOfMainOperationPhase, @"Checking for remote client device directory");
    
    [self checkWhetherRemoteClientDeviceDirectoryExists];
}

- (void)discoveredStatusOfRemoteClientDeviceDirectory:(TICDSRemoteFileStructureExistsResponseType)status
{
    switch( status ) {
        case TICDSRemoteFileStructureExistsResponseTypeError:
            TICDSLog(TICDSLogVerbosityErrorsOnly, @"Error checking for remote client device directory");
            [self operationDidFailToComplete];
            return;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client Device Directory exists!");
            [self setShouldCreateClientDirectory:NO];
            
            if( [self shouldUseEncryption] ) {
                [self beginTestForCorrectPassword];
            } else {
                [self operationDidCompleteSuccessfully];
            }
            break;
            
        case TICDSRemoteFileStructureExistsResponseTypeDoesNotExist:
            TICDSLog(TICDSLogVerbosityEveryStep, @"Client Device Directory does not exist");
            
            [self setShouldCreateClientDirectory:YES];
            
            if( [self shouldUseEncryption] ) {
                [self blitzKeychainItems];
                
                [self beginRequestForEncryptionPassword];
            } else {
                [self beginCreatingRemoteClientDeviceDirectory];
            }
            break;
    }
}

#pragma mark Overridden Method
- (void)checkWhetherRemoteClientDeviceDirectoryExists
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self discoveredStatusOfRemoteClientDeviceDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
}

#pragma mark - Password Testing
- (void)beginTestForCorrectPassword
{
    // Assume password is correct...
    TICDSLog(TICDSLogVerbosityStartAndEndOfEachOperationPhase, @"Fetching encryption password test file");
    
    [self fetchPasswordTestData];
}

- (void)fetchedPasswordTestData:(NSData *)testData
{
    if( testData ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Fetched test data and decrypted successfully");
        
        if( [self shouldCreateClientDirectory] ) {
            [self beginCreatingRemoteClientDeviceDirectory];
        } else {
            [self operationDidCompleteSuccessfully];
        }
        return;
    }
    
    // an error occurred
    NSError *underlyingError = [[[self error] userInfo] valueForKey:NSUnderlyingErrorKey];
    
    // incorrect password
    if( [underlyingError code] == FZACryptorErrorCodeFailedIntegrityCheck && [[underlyingError domain] isEqualToString:FZACryptorErrorDomain] ) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Password was incorrect, so ask the delegate for a new one");
        
        [self blitzKeychainItems];
        [self beginRequestForEncryptionPassword];
        return;
    }
    
    // generic error
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Failed to fetch test data");
    [self operationDidFailToComplete];
}

#pragma mark Overridden Method
- (void)fetchPasswordTestData
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeMethodNotOverriddenBySubclass classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedPasswordTestData:nil];
}

#pragma mark - Existing Encryption Password
- (void)beginRequestForEncryptionPassword
{
    if( [NSThread isMainThread] ) {
        [self performSelectorInBackground:@selector(beginRequestForEncryptionPassword) withObject:nil];
        return;
    }
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self setPaused:YES];
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Pausing registration because an encryption password is needed");
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationPausedToRequestEncryptionPassword:) waitUntilDone:NO];
    
    while( [self isPaused] ) {
        [NSThread sleepForTimeInterval:0.2];
    }
    
    TICDSLog(TICDSLogVerbosityEveryStep, @"Continuing application registration after determining encryption password");
    
    [self ti_alertDelegateOnMainThreadWithSelector:@selector(registrationOperationResumedFollowingPasswordProvision:) waitUntilDone:NO];
    
    [pool release];
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
    
    [[self cryptor] setPassword:[self password] salt:[self saltData]];
    
    [self beginTestForCorrectPassword];
}

#pragma mark -
#pragma mark Keychain
- (void)createCryptorIfNecessary
{
    if( [self cryptor] ) {
        return;
    }
    
    FZACryptor *cryptor = [[FZACryptor alloc] init];
    [self setCryptor:cryptor];
    [cryptor release];
}

- (void)blitzKeychainItems
{
    [self createCryptorIfNecessary];
    
    if( [[self cryptor] isConfigured] ) {
        NSLog(@"Deconfiguring cryptor for new registration");
        [[self cryptor] clearPasswordAndSalt];
    }
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
    [_saltData release], _saltData = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize appIdentifier = _appIdentifier;
@synthesize clientDescription = _clientDescription;
@synthesize applicationUserInfo = _applicationUserInfo;
@synthesize paused = _paused;
@synthesize password = _password;
@synthesize saltData = _saltData;
@synthesize shouldCreateClientDirectory = _shouldCreateClientDirectory;

@end
