//
//  TICDSDropboxSDKBasedApplicationRegistrationOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 13/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICDSDropboxSDKBasedApplicationRegistrationOperation.h"

@implementation TICDSDropboxSDKBasedApplicationRegistrationOperation

#pragma mark -
#pragma mark Helper Methods
- (void)createDirectoryContentsFromDictionary:(NSDictionary *)aDictionary inDirectory:(NSString *)aDirectoryPath
{
    for( NSString *eachName in [aDictionary allKeys] ) {
        
        id object = [aDictionary valueForKey:eachName];
        
        if( [object isKindOfClass:[NSDictionary class]] ) {
            NSString *thisPath = [aDirectoryPath stringByAppendingPathComponent:eachName];
            
            // create directory
            _numberOfAppDirectoriesToCreate++;
            
            [[self appDirectoryRestClient] createFolder:thisPath];
            
            [self createDirectoryContentsFromDictionary:object inDirectory:thisPath];            
        }
    }
}

#pragma mark -
#pragma mark Overridden Methods
- (BOOL)needsMainThread
{
    return YES;
}

#pragma mark Global App Directory Methods
- (void)checkWhetherRemoteGlobalAppDirectoryExists
{
    [[self appDirectoryRestClient] loadMetadata:[self applicationDirectoryPath]];
}

- (void)createRemoteGlobalAppDirectoryStructure
{
    [self createDirectoryContentsFromDictionary:[TICDSUtilities remoteGlobalAppDirectoryHierarchy] inDirectory:[self applicationDirectoryPath]];
}

- (void)checkForGlobalAppDirectoryCompletion
{
    if( _numberOfAppDirectoriesThatWereCreated == _numberOfAppDirectoriesToCreate ) {
        [self createdRemoteGlobalAppDirectoryStructureWithSuccess:YES];
        return;
    }
    
    if( _numberOfAppDirectoriesThatWereCreated + _numberOfAppDirectoriesThatFailedToBeCreated == _numberOfAppDirectoriesToCreate ) {
        [self createdRemoteGlobalAppDirectoryStructureWithSuccess:NO];
        return;
    }
}

- (void)copyReadMeTxtFileToRootOfGlobalAppDirectoryFromPath:(NSString *)aPath
{
    [[self appDirectoryRestClient] uploadFile:[aPath lastPathComponent] toPath:[self applicationDirectoryPath] fromPath:[aPath stringByDeletingLastPathComponent]];
}

#pragma mark Salt
- (void)checkWhetherSaltFileExists
{
    [[self appDirectoryRestClient] loadMetadata:[self encryptionDirectorySaltDataFilePath]];
}

- (void)fetchSaltData
{
    [[self appDirectoryRestClient] loadFile:[self encryptionDirectorySaltDataFilePath] intoPath:[[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSSaltFilenameWithExtension]];
}

- (void)saveSaltDataToRemote:(NSData *)saltData
{
    NSString *tempFile = [[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSSaltFilenameWithExtension];
    
    NSError *anyError = nil;
    BOOL success = [saltData writeToFile:tempFile options:0 error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self savedSaltDataToRootOfGlobalAppDirectoryWithSuccess:success];
        return;
    }
    
    [[self appDirectoryRestClient] uploadFile:TICDSSaltFilenameWithExtension toPath:[[self encryptionDirectorySaltDataFilePath] stringByDeletingLastPathComponent] fromPath:tempFile];
}

#pragma mark Password Test
- (void)savePasswordTestData:(NSData *)testData
{
    NSString *tempFile = [[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSEncryptionTestFilenameWithExtension];
    
    NSError *anyError = nil;
    BOOL success = [testData writeToFile:tempFile options:0 error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self savedPasswordTestDataWithSuccess:success];
        return;
    }
    
    [[self appDirectoryRestClient] uploadFile:TICDSEncryptionTestFilenameWithExtension toPath:[[self encryptionDirectoryTestDataFilePath] stringByDeletingLastPathComponent] fromPath:tempFile];
}

- (void)fetchPasswordTestData
{
    [[self appDirectoryRestClient] loadFile:[self encryptionDirectoryTestDataFilePath] intoPath:[[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSEncryptionTestFilenameWithExtension]];
}

#pragma makr Client Device Directories Methods
- (void)checkWhetherRemoteClientDeviceDirectoryExists
{
    [[self appDirectoryRestClient] loadMetadata:[self clientDevicesThisClientDeviceDirectoryPath]];
}

- (void)createRemoteClientDeviceDirectory
{
    [[self appDirectoryRestClient] createFolder:[self clientDevicesThisClientDeviceDirectoryPath]];
}

- (void)saveRemoteClientDeviceInfoPlistFromDictionary:(NSDictionary *)aDictionary
{
    BOOL success = YES;
    NSString *finalFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
    
    if( [self shouldUseEncryption] ) {
        NSString *tmpFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
        tmpFilePath = [tmpFilePath stringByAppendingFormat:@"tmp"];
        
        success = [aDictionary writeToFile:tmpFilePath atomically:NO];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
            [self savedRemoteClientDeviceInfoPlistWithSuccess:success];
            return;
        }
        
        NSError *anyError = nil;
        success = [[self cryptor] encryptFileAtLocation:[NSURL fileURLWithPath:tmpFilePath] writingToLocation:[NSURL fileURLWithPath:finalFilePath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self savedRemoteClientDeviceInfoPlistWithSuccess:success];
            return;
        }
    } else {
        success = [aDictionary writeToFile:finalFilePath atomically:NO];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
            [self savedRemoteClientDeviceInfoPlistWithSuccess:success];
            return;
        }
    }
    
    [[self appDirectoryRestClient] uploadFile:TICDSDeviceInfoPlistFilenameWithExtension toPath:[self clientDevicesThisClientDeviceDirectoryPath] fromPath:finalFilePath];
}

#pragma mark -
#pragma mark Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    NSString *path = [metadata path];
    TICDSRemoteFileStructureExistsResponseType status = [metadata isDeleted] ? TICDSRemoteFileStructureExistsResponseTypeDoesNotExist : TICDSRemoteFileStructureExistsResponseTypeDoesExist;
    
    if( [path isEqualToString:[self applicationDirectoryPath]] ) {
        [self discoveredStatusOfRemoteGlobalAppDirectory:status];
        return;
    }
    
    if( [path isEqualToString:[self encryptionDirectorySaltDataFilePath]] ) {
        [self discoveredStatusOfSaltFile:status];
        return;
    }
    
    if( [path isEqualToString:[self clientDevicesThisClientDeviceDirectoryPath]] ) {
        [self discoveredStatusOfRemoteClientDeviceDirectory:status];
        return;
    }
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path
{
    
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    NSInteger errorCode = [error code];
    BOOL notFound = YES;
    
    if( errorCode != 404 ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
        notFound = NO;
    }
    
    if( [path isEqualToString:[self applicationDirectoryPath]] ) {
        if( notFound ) {
            [self discoveredStatusOfRemoteGlobalAppDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        } else {
            [self discoveredStatusOfRemoteGlobalAppDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
        }
        return;
    }
    
    if( [path isEqualToString:[self encryptionDirectorySaltDataFilePath]] ) {
        if( notFound ) {
            [self discoveredStatusOfSaltFile:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        } else {
            [self discoveredStatusOfSaltFile:TICDSRemoteFileStructureExistsResponseTypeError];
        }
        return;
    }
    
    if( [path isEqualToString:[self clientDevicesThisClientDeviceDirectoryPath]] ) {
        if( notFound ) {
            [self discoveredStatusOfRemoteClientDeviceDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        } else {
            [self discoveredStatusOfRemoteClientDeviceDirectory:TICDSRemoteFileStructureExistsResponseTypeError];
        }
        return;
    }
}

#pragma mark Directories
- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder
{
    NSString *path = [folder path];
    
    if( [path isEqualToString:[self clientDevicesThisClientDeviceDirectoryPath]] ) {
        [self createdRemoteClientDeviceDirectoryWithSuccess:YES];
        return;
    }
    
    // if we get here, it's a global app directory
    _numberOfAppDirectoriesThatWereCreated++;
    
    [self checkForGlobalAppDirectoryCompletion];
}

- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [path isEqualToString:[self clientDevicesThisClientDeviceDirectoryPath]] ) {
        [self createdRemoteClientDeviceDirectoryWithSuccess:NO];
        return;
    }
    
    // if we here, it's a global app directory
    _numberOfAppDirectoriesThatFailedToBeCreated++;
    
    [self checkForGlobalAppDirectoryCompletion];
}

#pragma mark Uploads
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
{
    if( [destPath isEqualToString:[[self clientDevicesThisClientDeviceDirectoryPath] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension]] ) {
        [self savedRemoteClientDeviceInfoPlistWithSuccess:YES];
        return;
    }
    
    if( [[destPath stringByDeletingLastPathComponent] isEqualToString:[self applicationDirectoryPath]] ) {
        // uploaded the ReadMe.txt file
        [self copiedReadMeTxtFileToRootOfGlobalAppDirectoryWithSuccess:YES];
        return;
    }
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSSaltFilenameWithExtension] ) {
        [self savedSaltDataToRootOfGlobalAppDirectoryWithSuccess:YES];
        return;
    }
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSEncryptionTestFilenameWithExtension] ) {
        [self savedPasswordTestDataWithSuccess:YES];
        return;
    }
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [path isEqualToString:[[self clientDevicesThisClientDeviceDirectoryPath] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension]] ) {
        [self savedRemoteClientDeviceInfoPlistWithSuccess:NO];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self applicationDirectoryPath]] ) {
        // failed to upload the ReadMe.txt file
        [self copiedReadMeTxtFileToRootOfGlobalAppDirectoryWithSuccess:NO];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSSaltFilenameWithExtension] ) {
        [self savedSaltDataToRootOfGlobalAppDirectoryWithSuccess:NO];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSEncryptionTestFilenameWithExtension] ) {
        [self savedPasswordTestDataWithSuccess:NO];
        return;
    }
}

#pragma mark Downloads
- (void)restClient:(DBRestClient *)client loadedFile:(NSString *)destPath
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSSaltFilenameWithExtension] ) {
        NSData *saltData = [NSData dataWithContentsOfFile:destPath options:0 error:&anyError];
        
        if( !saltData ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        }
        
        [self fetchedSaltData:saltData];
        return;
    }
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSEncryptionTestFilenameWithExtension] ) {
        NSString *unencryptPath = [destPath stringByAppendingPathExtension:@"tst"];
        
        success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:destPath] writingToLocation:[NSURL fileURLWithPath:unencryptPath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self fetchedPasswordTestData:nil];
            return;
        }
        
        NSData *testData = [NSData dataWithContentsOfFile:unencryptPath options:0 error:&anyError];
        
        if( !testData ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        }
        
        [self fetchedPasswordTestData:testData];
        return;
    }
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [[path lastPathComponent] isEqualToString:TICDSSaltFilenameWithExtension] ) {
        [self fetchedSaltData:nil];
    }
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_dbSession release], _dbSession = nil;
    [_appDirectoryRestClient release], _appDirectoryRestClient = nil;
    [_applicationDirectoryPath release], _applicationDirectoryPath = nil;
    [_encryptionDirectorySaltDataFilePath release], _encryptionDirectorySaltDataFilePath = nil;
    [_encryptionDirectoryTestDataFilePath release], _encryptionDirectoryTestDataFilePath = nil;
    [_clientDevicesThisClientDeviceDirectoryPath release], _clientDevicesThisClientDeviceDirectoryPath = nil;

    [super dealloc];
}

#pragma mark -
#pragma mark Lazy Accessors
- (DBRestClient *)appDirectoryRestClient
{
    if( _appDirectoryRestClient ) return _appDirectoryRestClient;
    
    _appDirectoryRestClient = [[DBRestClient alloc] initWithSession:[self dbSession]];
    [_appDirectoryRestClient setDelegate:self];
    
    return _appDirectoryRestClient;
}

#pragma mark -
#pragma mark Properties
@synthesize dbSession = _dbSession;
@synthesize appDirectoryRestClient = _appDirectoryRestClient;
@synthesize applicationDirectoryPath = _applicationDirectoryPath;
@synthesize encryptionDirectorySaltDataFilePath = _encryptionDirectorySaltDataFilePath;
@synthesize encryptionDirectoryTestDataFilePath = _encryptionDirectoryTestDataFilePath;
@synthesize clientDevicesThisClientDeviceDirectoryPath = _clientDevicesThisClientDeviceDirectoryPath;

@end
