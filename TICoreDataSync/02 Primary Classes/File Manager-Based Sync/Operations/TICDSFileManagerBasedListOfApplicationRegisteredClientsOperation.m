//
//  TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation.m
//  Notebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedListOfApplicationRegisteredClientsOperation

- (void)fetchArrayOfClientUUIDStrings
{
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[self clientDevicesDirectoryPath] error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedArrayOfClientUUIDStrings:contents];
}

- (void)fetchDeviceInfoDictionaryForClientWithIdentifier:(NSString *)anIdentifier
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    NSString *filePath = [[[self clientDevicesDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
    
    if( [self shouldUseEncryption] ) {
        NSString *tmpFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:anIdentifier];
        
        success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:filePath] writingToLocation:[NSURL fileURLWithPath:tmpFilePath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self fetchedDeviceInfoDictionary:nil forClientWithIdentifier:anIdentifier];
            return;
        }
        
        filePath = tmpFilePath;
    }
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
    
    if( !dictionary ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedDeviceInfoDictionary:dictionary forClientWithIdentifier:anIdentifier];
}

- (void)fetchArrayOfDocumentUUIDStrings
{
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[self documentsDirectoryPath] error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedArrayOfDocumentUUIDStrings:contents];
}

- (void)fetchArrayOfClientsRegisteredForDocumentWithIdentifier:(NSString *)anIdentifier
{
    NSError *anyError = nil;
    NSString *path = [[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSSyncChangesDirectoryName];
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:path error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedArrayOfClients:contents registeredForDocumentWithIdentifier:anIdentifier];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _clientDevicesDirectoryPath = nil;
    _documentsDirectoryPath = nil;

}

#pragma mark - Properties
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize documentsDirectoryPath = _documentsDirectoryPath;

@end
