//
//  TICDSFileManagerBasedApplicationRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 22/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSFileManagerBasedApplicationRegistrationOperation

#pragma mark -
#pragma mark Helper Methods
- (BOOL)createDirectoryContentsFromDictionary:(NSDictionary *)aDictionary inDirectory:(NSString *)aDirectoryPath
{
    NSError *anyError = nil;
    
    for( NSString *eachName in [aDictionary allKeys] ) {
        
        id object = [aDictionary valueForKey:eachName];
        
        if( eachName == kTICDSUtilitiesFileStructureClientDeviceUID ) {
            eachName = [self clientIdentifier];
        }
        
        if( [object isKindOfClass:[NSDictionary class]] ) {
            NSString *thisPath = [aDirectoryPath stringByAppendingPathComponent:eachName];
            
            // create directory
            BOOL success = [[self fileManager] createDirectoryAtPath:thisPath withIntermediateDirectories:YES attributes:nil error:&anyError];
            if( !success ) {
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                return NO;
            }
            
            success = [self createDirectoryContentsFromDictionary:object inDirectory:thisPath];
            if( !success ) {
                return NO;
            }
            
        }
    }
    
    return YES;
}

#pragma mark -
#pragma mark Overridden Global App Directory Methods
- (void)checkWhetherRemoteGlobalAppDirectoryExists
{
    if( [[self fileManager] fileExistsAtPath:[self applicationDirectoryPath]] ) {
        [self discoveredStatusOfRemoteGlobalAppDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfRemoteGlobalAppDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)createRemoteGlobalAppDirectoryStructure
{
    NSDictionary *appStructure = [TICDSUtilities remoteGlobalAppFileStructure];
    
    NSError *anyError = nil;
    BOOL success = [self createDirectoryContentsFromDictionary:appStructure inDirectory:[self applicationDirectoryPath]];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdRemoteGlobalAppDirectoryStructureWithSuccess:success];
}

- (void)copyReadMeTxtFileToRootOfGlobalAppDirectoryFromPath:(NSString *)aPath
{
    NSString *remotePath = [[self applicationDirectoryPath] stringByAppendingPathComponent:[aPath lastPathComponent]];
    
    NSError *anyError = nil;
    BOOL success = [[self fileManager] copyItemAtPath:aPath toPath:remotePath error:&anyError];
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self copiedReadMeTxtFileToRootOfGlobalAppDirectoryWithSuccess:success];
}

- (void)checkWhetherSaltFileExists
{
    NSString *remotePath = [[self applicationDirectoryPath] stringByAppendingPathComponent:TICDSSaltFilenameWithExtension];
    
    if( [[self fileManager] fileExistsAtPath:remotePath] ) {
        [self discoveredStatusOfSaltFile:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfSaltFile:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)fetchSaltData
{
    NSString *remotePath = [[self applicationDirectoryPath] stringByAppendingPathComponent:TICDSSaltFilenameWithExtension];
    
    NSData *saltData = [NSData dataWithContentsOfFile:remotePath];
    
    [self fetchedSaltData:saltData];
}

- (void)saveSaltDataToRootOfGlobalAppDirectory:(NSData *)saltData
{
    NSString *remotePath = [[self applicationDirectoryPath] stringByAppendingPathComponent:TICDSSaltFilenameWithExtension];
    
    NSError *anyError = nil;
    BOOL success = [saltData writeToFile:remotePath options:0 error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self savedSaltDataToRootOfGlobalAppDirectoryWithSuccess:success];
}

#pragma mark -
#pragma mark Overridden Client Device Directory Methods
- (void)checkWhetherRemoteClientDeviceDirectoryExists
{
    if( [[self fileManager] fileExistsAtPath:[self clientDevicesThisClientDeviceDirectoryPath]] ) {
        [self discoveredStatusOfRemoteClientDeviceDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfRemoteClientDeviceDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)createRemoteClientDeviceDirectory
{
    NSError *anyError = nil;
    BOOL success = [[self fileManager] createDirectoryAtPath:[self clientDevicesThisClientDeviceDirectoryPath] withIntermediateDirectories:YES attributes:nil error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdRemoteClientDeviceDirectoryWithSuccess:success];
}

- (void)saveRemoteClientDeviceInfoPlistFromDictionary:(NSDictionary *)aDictionary
{
    NSString *filePath = [[self clientDevicesThisClientDeviceDirectoryPath] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
    
    BOOL success = [aDictionary writeToFile:filePath atomically:NO];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self savedRemoteClientDeviceInfoPlistWithSuccess:success];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_applicationDirectoryPath release], _applicationDirectoryPath = nil;
    [_clientDevicesDirectoryPath release], _clientDevicesDirectoryPath = nil;
    [_clientDevicesThisClientDeviceDirectoryPath release], _clientDevicesThisClientDeviceDirectoryPath = nil;
    
    [super dealloc];
}

#pragma mark -
#pragma mark Properties
@synthesize applicationDirectoryPath = _applicationDirectoryPath;
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize clientDevicesThisClientDeviceDirectoryPath = _clientDevicesThisClientDeviceDirectoryPath;

@end
