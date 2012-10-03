//
//  TICDSFileManagerBasedListOfDocumentRegisteredClientsOperation.m
//  Notebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedListOfDocumentRegisteredClientsOperation

- (void)fetchArrayOfClientUUIDStrings
{
    NSError *anyError = nil;
    NSArray *files = [[self fileManager] contentsOfDirectoryAtPath:[self thisDocumentSyncChangesDirectoryPath] error:&anyError];
    
    if( !files ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedArrayOfClientUUIDStrings:files];
}

- (void)fetchDeviceInfoDictionaryForClientWithIdentifier:(NSString *)anIdentifier
{
    NSError *anyError = nil;
    BOOL success = YES;
    NSString *finalFilePath = [self pathToDeviceInfoPlistForDeviceWithIdentifier:anIdentifier];
    
    if( [self shouldUseEncryption] ) {
        NSString *tempFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:anIdentifier];
        
        success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:finalFilePath] writingToLocation:[NSURL fileURLWithPath:tempFilePath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self fetchedDeviceInfoDictionary:nil forClientWithIdentifier:anIdentifier];
        }
        
        finalFilePath = tempFilePath;
    }
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:finalFilePath];
    
    [self fetchedDeviceInfoDictionary:dictionary forClientWithIdentifier:anIdentifier];
}

- (void)fetchLastSynchronizationDates
{
    NSString *filePath = nil;
    NSDictionary *attributes = nil;
    NSError *anyError = nil;
    
    for( NSString *eachIdentifier in [self synchronizedClientIdentifiers] ) {
        filePath = [[self thisDocumentRecentSyncsDirectoryPath] stringByAppendingPathComponent:eachIdentifier];
        filePath = [filePath stringByAppendingPathExtension:TICDSRecentSyncFileExtension];
        
        attributes = [[self fileManager] attributesOfItemAtPath:filePath error:&anyError];
        
        if( !attributes ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        }
        
        [self fetchedLastSynchronizationDate:[attributes valueForKey:NSFileModificationDate] forClientWithIdentifier:eachIdentifier];
    }
}

- (void)fetchModificationDateOfWholeStoreForClientWithIdentifier:(NSString *)anIdentifier
{
    NSString *filePath = [self pathToWholeStoreFileForDeviceWithIdentifier:anIdentifier];
    NSError *anyError = nil;
    NSDictionary *attributes = [[self fileManager] attributesOfItemAtPath:filePath error:&anyError];
    
    if( !attributes ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedModificationDate:[attributes valueForKey:NSFileModificationDate]ofWholeStoreForClientWithIdentifier:anIdentifier];
}

#pragma mark - Relative Paths
- (NSString *)pathToDeviceInfoPlistForDeviceWithIdentifier:(NSString *)anIdentifier
{
    return [[[self clientDevicesDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
}

- (NSString *)pathToWholeStoreFileForDeviceWithIdentifier:(NSString *)anIdentifier
{
    return [[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSWholeStoreFilename];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _thisDocumentSyncChangesDirectoryPath = nil;
    _clientDevicesDirectoryPath = nil;
    _thisDocumentRecentSyncsDirectoryPath = nil;
    _thisDocumentWholeStoreDirectoryPath = nil;

}

#pragma mark - Properties
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize thisDocumentRecentSyncsDirectoryPath = _thisDocumentRecentSyncsDirectoryPath;
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;

@end
