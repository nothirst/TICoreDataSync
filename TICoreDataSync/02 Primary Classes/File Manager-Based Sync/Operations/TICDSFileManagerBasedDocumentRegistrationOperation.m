//
//  TICDSFileManagerBasedDocumentRegistrationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 23/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSFileManagerBasedDocumentRegistrationOperation

#pragma mark - Helper Methods
- (BOOL)createDirectoryContentsFromDictionary:(NSDictionary *)aDictionary inDirectory:(NSString *)aPath
{
    NSError *anyError = nil;
    
    for( NSString *eachName in [aDictionary allKeys] ) {
        
        id object = [aDictionary valueForKey:eachName];
        
        if( [object isKindOfClass:[NSDictionary class]] ) {
            NSString *thisPath = [aPath stringByAppendingPathComponent:eachName];
            
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

#pragma mark - Overridden Document Methods
- (void)checkWhetherRemoteDocumentDirectoryExists
{
    if( [[self fileManager] fileExistsAtPath:[self thisDocumentDirectoryPath]] ) {
        [self discoveredStatusOfRemoteDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfRemoteDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)checkWhetherRemoteDocumentWasDeleted
{
    if( [[self fileManager] fileExistsAtPath:[self deletedDocumentsThisDocumentIdentifierPlistPath]] ) {
        [self discoveredDeletionStatusOfRemoteDocument:TICDSRemoteFileStructureDeletionResponseTypeDeleted];
    } else {
        [self discoveredDeletionStatusOfRemoteDocument:TICDSRemoteFileStructureDeletionResponseTypeNotDeleted];
    }
}

- (void)createRemoteDocumentDirectoryStructure
{
    NSDictionary *documentStructure = [TICDSUtilities remoteDocumentDirectoryHierarchy];
    
    NSError *anyError = nil;
    BOOL success = [self createDirectoryContentsFromDictionary:documentStructure inDirectory:[self thisDocumentDirectoryPath]];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdRemoteDocumentDirectoryStructureWithSuccess:success];
}

- (void)saveRemoteDocumentInfoPlistFromDictionary:(NSDictionary *)aDictionary
{
    BOOL success = YES;
    NSString *finalFilePath = [[self thisDocumentDirectoryPath] stringByAppendingPathComponent:TICDSDocumentInfoPlistFilenameWithExtension];
    
    if( ![self shouldUseEncryption] ) {
        success = [aDictionary writeToFile:finalFilePath atomically:NO];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
        }
        
        [self savedRemoteDocumentInfoPlistWithSuccess:success];
        return;
    }
    
    // if encryption, save to temporary directory first, then encrypt, writing directly to final location
    NSString *tmpFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSDocumentInfoPlistFilenameWithExtension];
    
    success = [aDictionary writeToFile:tmpFilePath atomically:NO];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
        [self savedRemoteDocumentInfoPlistWithSuccess:success];
        return;
    }
    
    NSError *anyError = nil;
    success = [[self cryptor] encryptFileAtLocation:[NSURL fileURLWithPath:tmpFilePath] writingToLocation:[NSURL fileURLWithPath:finalFilePath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self savedRemoteDocumentInfoPlistWithSuccess:success];
}

- (void)saveIntegrityKey:(NSString *)aKey
{
    NSString *finalPath = [[[self thisDocumentDirectoryPath] stringByAppendingPathComponent:TICDSIntegrityKeyDirectoryName] stringByAppendingPathComponent:aKey];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:[self clientIdentifier] forKey:kTICDSOriginalDeviceIdentifier];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    
    NSError *anyError = nil;
    BOOL success = [data writeToFile:finalPath options:0 error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self savedIntegrityKeyWithSuccess:success];
}

- (void)fetchRemoteIntegrityKey
{
    NSString *integrityDirectoryPath = [[self thisDocumentDirectoryPath] stringByAppendingPathComponent:TICDSIntegrityKeyDirectoryName];
    
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:integrityDirectoryPath error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self fetchedRemoteIntegrityKey:nil];
        return;
    }
    
    for( NSString *eachFile in contents ) {
        if( [eachFile length] < 5 ) {
            continue;
        }
        
        [self fetchedRemoteIntegrityKey:eachFile];
        return;
    }
    
    [self fetchedRemoteIntegrityKey:nil];
}

- (void)fetchListOfIdentifiersOfAllRegisteredClientsForThisApplication
{
    NSError *anyError = nil;
    
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[self clientDevicesDirectoryPath] error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedListOfIdentifiersOfAllRegisteredClientsForThisApplication:contents];
}

- (void)addDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:(NSString *)anIdentifier
{
    NSError *anyError = nil;
    
    NSString *deviceInfoPlistPath = [[[self clientDevicesDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
    
    NSString *finalFilePath = [[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension];
    
    BOOL success = [[self fileManager] copyItemAtPath:deviceInfoPlistPath toPath:finalFilePath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self addedDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:anIdentifier withSuccess:success];
}

- (void)deleteDocumentInfoPlistFromDeletedDocumentsDirectory
{
    NSError *anyError = nil;
    BOOL success = [[self fileManager] removeItemAtPath:[self deletedDocumentsThisDocumentIdentifierPlistPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:success];
}

#pragma mark - Overridden Client Device Directories
- (void)checkWhetherClientDirectoryExistsInRemoteDocumentSyncChangesDirectory
{
    if( [[self fileManager] fileExistsAtPath:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        [self discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
    } else {
        [self discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
    }
}

- (void)checkWhetherClientWasDeletedFromRemoteDocument
{
    if( [[self fileManager] fileExistsAtPath:[[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:[self clientIdentifier]] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension]] ) {
        [self discoveredDeletionStatusOfClient:TICDSRemoteFileStructureDeletionResponseTypeDeleted];
    } else {
        [self discoveredDeletionStatusOfClient:TICDSRemoteFileStructureDeletionResponseTypeNotDeleted];
    }
}

- (void)deleteClientIdentifierFileFromDeletedClientsDirectory
{
    NSString *filePath = [[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:[self clientIdentifier]] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension];
    
    NSError *anyError = nil;
    BOOL success = [[self fileManager] removeItemAtPath:filePath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:success];
}

- (void)createClientDirectoriesInRemoteDocumentDirectories
{
    NSError *anyError = nil;
    BOOL success = NO;
    success = [[self fileManager] createDirectoryAtPath:[self thisDocumentSyncChangesThisClientDirectoryPath] withIntermediateDirectories:NO attributes:nil error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:NO];
        return;
    }
    
    success = [[self fileManager] createDirectoryAtPath:[self thisDocumentSyncCommandsThisClientDirectoryPath] withIntermediateDirectories:NO attributes:nil error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:success];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _documentsDirectoryPath = nil;
    _clientDevicesDirectoryPath = nil;
    _thisDocumentDeletedClientsDirectoryPath = nil;
    _deletedDocumentsThisDocumentIdentifierPlistPath = nil;
    _thisDocumentDirectoryPath = nil;
    _thisDocumentSyncChangesThisClientDirectoryPath = nil;
    _thisDocumentSyncCommandsThisClientDirectoryPath = nil;

}

#pragma mark - Properties
@synthesize documentsDirectoryPath = _documentsDirectoryPath;
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize deletedDocumentsThisDocumentIdentifierPlistPath = _deletedDocumentsThisDocumentIdentifierPlistPath;
@synthesize thisDocumentDeletedClientsDirectoryPath = _thisDocumentDeletedClientsDirectoryPath;
@synthesize thisDocumentDirectoryPath = _thisDocumentDirectoryPath;
@synthesize thisDocumentSyncChangesThisClientDirectoryPath = _thisDocumentSyncChangesThisClientDirectoryPath;
@synthesize thisDocumentSyncCommandsThisClientDirectoryPath = _thisDocumentSyncCommandsThisClientDirectoryPath;

@end
