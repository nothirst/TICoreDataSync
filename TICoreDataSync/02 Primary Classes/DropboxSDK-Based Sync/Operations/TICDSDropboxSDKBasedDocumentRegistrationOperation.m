//
//  TICDSDropboxSDKBasedDocumentRegistrationOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICDSDropboxSDKBasedDocumentRegistrationOperation.h"

@implementation TICDSDropboxSDKBasedDocumentRegistrationOperation

#pragma mark -
#pragma mark Helper Methods
- (void)createDirectoryContentsFromDictionary:(NSDictionary *)aDictionary inDirectory:(NSString *)aDirectoryPath
{
    for( NSString *eachName in [aDictionary allKeys] ) {
        
        id object = [aDictionary valueForKey:eachName];
        
        if( [object isKindOfClass:[NSDictionary class]] ) {
            NSString *thisPath = [aDirectoryPath stringByAppendingPathComponent:eachName];
            
            // only issue a DropboxSDK directory creation request for the lowest-level nested directory
            // i.e., if this directory is empty
            if( [object count] < 1 ) {
                // create directory
                _numberOfDocumentDirectoriesToCreate++;
                
                [[self restClient] createFolder:thisPath];
            } else {
                [self createDirectoryContentsFromDictionary:object inDirectory:thisPath];
            }
        }
    }
}

#pragma mark -
#pragma mark Overridden Document Methods
- (BOOL)needsMainThread
{
    return YES;
}

#pragma mark -
#pragma mark Document Directory
- (void)checkWhetherRemoteDocumentDirectoryExists
{
    [[self restClient] loadMetadata:[self thisDocumentDirectoryPath]];
}

- (void)checkWhetherRemoteDocumentWasDeleted
{
    [[self restClient] loadMetadata:[self deletedDocumentsDirectoryIdentifierPlistFilePath]];
}

- (void)createRemoteDocumentDirectoryStructure
{
    [self createDirectoryContentsFromDictionary:[TICDSUtilities remoteDocumentDirectoryHierarchy] inDirectory:[self thisDocumentDirectoryPath]];
}

- (void)checkForRemoteDocumentDirectoryCompletion
{
    if( _numberOfDocumentDirectoriesThatWereCreated == _numberOfDocumentDirectoriesToCreate ) {
        [self createdRemoteDocumentDirectoryStructureWithSuccess:YES];
        return;
    }
    
    if( _numberOfDocumentDirectoriesThatWereCreated + _numberOfDocumentDirectoriesThatFailedToBeCreated == _numberOfDocumentDirectoriesToCreate ) {
        [self createdRemoteDocumentDirectoryStructureWithSuccess:NO];
        return;
    }
}

#pragma mark documentInfo.plist
- (void)saveRemoteDocumentInfoPlistFromDictionary:(NSDictionary *)aDictionary
{
    BOOL success = YES;
    NSError *anyError = nil;
    
    NSString *finalFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSDocumentInfoPlistFilenameWithExtension];
    
    if( [self shouldUseEncryption] ) {
        NSString *cryptFilePath = [finalFilePath stringByAppendingFormat:@"tmp"];
        
        success = [aDictionary writeToFile:cryptFilePath atomically:NO];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
            [self savedRemoteDocumentInfoPlistWithSuccess:NO];
            return;
        }
        
        success = [[self cryptor] encryptFileAtLocation:[NSURL fileURLWithPath:cryptFilePath] writingToLocation:[NSURL fileURLWithPath:finalFilePath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        }
    } else {
        success = [aDictionary writeToFile:finalFilePath atomically:NO];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
        }
    }
    
    if( !success ) {
        [self savedRemoteDocumentInfoPlistWithSuccess:NO];
        return;
    }
    
    // The document info plist will not exist in this point in the workflow. There is no point in doing the dance to figure out if there is a parent revision because there won't be one.
    [[self restClient] uploadFile:TICDSDocumentInfoPlistFilenameWithExtension toPath:[self thisDocumentDirectoryPath] withParentRev:nil fromPath:finalFilePath];
}

#pragma mark Integrity Key
- (void)fetchRemoteIntegrityKey
{
    NSString *directoryPath = [[self thisDocumentDirectoryPath] stringByAppendingPathComponent:TICDSIntegrityKeyDirectoryName];
    
    [[self restClient] loadMetadata:directoryPath];
}

- (void)saveIntegrityKey:(NSString *)aKey
{
    NSString *remoteDirectory = [[self thisDocumentDirectoryPath] stringByAppendingPathComponent:TICDSIntegrityKeyDirectoryName];
    NSString *localFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:aKey];
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithObject:[self clientIdentifier] forKey:kTICDSOriginalDeviceIdentifier];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    
    NSError *anyError = nil;
    if( [[self fileManager] fileExistsAtPath:localFilePath] && ![[self fileManager] removeItemAtPath:localFilePath error:&anyError] ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        return;
    }
    
    BOOL success = [data writeToFile:localFilePath options:0 error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self savedIntegrityKeyWithSuccess:success];
        return;
    }
  
    // The integrity will not exist in this point in the workflow. There is no point in doing the dance to figure out if there is a parent revision because there won't be one.
    [[self restClient] uploadFile:aKey toPath:remoteDirectory withParentRev:nil fromPath:localFilePath];
}

#pragma mark Adding Other Clients to Document's DeletedClients Directory
- (void)fetchListOfIdentifiersOfAllRegisteredClientsForThisApplication
{
    [[self restClient] loadMetadata:[self clientDevicesDirectoryPath]];
}

- (void)addDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:(NSString *)anIdentifier
{
    NSString *documentInfoPlistPath = [[[self clientDevicesDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
    
    NSString *finalFilePath = [[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension];
    
    [[self restClient] copyFrom:documentInfoPlistPath toPath:finalFilePath];
}

#pragma mark Removing DeletedDocuments file
- (void)deleteDocumentInfoPlistFromDeletedDocumentsDirectory
{
    [[self restClient] deletePath:[self deletedDocumentsDirectoryIdentifierPlistFilePath]];
}

#pragma mark -
#pragma mark Client Directories
- (void)checkWhetherClientDirectoryExistsInRemoteDocumentSyncChangesDirectory
{
    [[self restClient] loadMetadata:[self thisDocumentSyncChangesThisClientDirectoryPath]];
}

- (void)checkWhetherClientWasDeletedFromRemoteDocument
{
    [[self restClient] loadMetadata:[[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:[self clientIdentifier]] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension]];
}

- (void)deleteClientIdentifierFileFromDeletedClientsDirectory
{
    [[self restClient] deletePath:[[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:[self clientIdentifier]] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension]];
}

- (void)createClientDirectoriesInRemoteDocumentDirectories
{
    [[self restClient] createFolder:[self thisDocumentSyncChangesThisClientDirectoryPath]];
    [[self restClient] createFolder:[self thisDocumentSyncCommandsThisClientDirectoryPath]];
}

- (void)checkForThisDocumentClientDirectoryCompletion
{
    if( _completedThisDocumentSyncChangesThisClientDirectory && _completedThisDocumentSyncChangesThisClientDirectory && (_errorCreatingThisDocumentSyncChangesThisClientDirectory || _errorCreatingThisDocumentSyncCommandsThisClientDirectory) ) {
        [self createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:NO];
    }
    
    if( _completedThisDocumentSyncChangesThisClientDirectory && _completedThisDocumentSyncCommandsThisClientDirectory ) {
        [self createdClientDirectoriesInRemoteDocumentDirectoriesWithSuccess:YES];
    }
}

#pragma mark -
#pragma mark Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    NSString *path = [metadata path];
    TICDSRemoteFileStructureExistsResponseType status = [metadata isDeleted] ? TICDSRemoteFileStructureExistsResponseTypeDoesNotExist : TICDSRemoteFileStructureExistsResponseTypeDoesExist;
    
    if( [path isEqualToString:[self thisDocumentDirectoryPath]] ) {
        [self discoveredStatusOfRemoteDocumentDirectory:status];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        [self discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:status];
        return;
    }
    
    if( [path isEqualToString:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self discoveredDeletionStatusOfRemoteDocument:[metadata isDeleted] ? TICDSRemoteFileStructureDeletionResponseTypeNotDeleted : TICDSRemoteFileStructureDeletionResponseTypeDeleted];
        return;
    }
    
    if( [path isEqualToString:[self clientDevicesDirectoryPath]] ) {
        NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:[[metadata contents] count]];
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( [[[eachSubMetadata path] lastPathComponent] length] < 5 ) {
                continue;
            }
            
            [identifiers addObject:[[eachSubMetadata path] lastPathComponent]];
        }
        
        [self fetchedListOfIdentifiersOfAllRegisteredClientsForThisApplication:identifiers];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSIntegrityKeyDirectoryName] ) {
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( [[[eachSubMetadata path] lastPathComponent] length] < 5 ) {
                continue;
            }
            
            [self fetchedRemoteIntegrityKey:[[eachSubMetadata path] lastPathComponent]];
            return;
        }
        
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeUnexpectedOrIncompleteFileLocationOrDirectoryStructure classAndMethod:__PRETTY_FUNCTION__]];
        [self fetchedRemoteIntegrityKey:nil];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentDeletedClientsDirectoryPath]] ) {
        [self discoveredDeletionStatusOfClient:TICDSRemoteFileStructureDeletionResponseTypeDeleted];
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
    TICDSRemoteFileStructureExistsResponseType status = TICDSRemoteFileStructureExistsResponseTypeDoesNotExist;
    
    if( errorCode != 404 ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
        status = TICDSRemoteFileStructureExistsResponseTypeError;
    }
    
    if( [path isEqualToString:[self thisDocumentDirectoryPath]] ) {
        [self discoveredStatusOfRemoteDocumentDirectory:status];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        [self discoveredStatusOfClientDirectoryInRemoteDocumentSyncChangesDirectory:status];
        return;
    }
    
    if( [path isEqualToString:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self discoveredDeletionStatusOfRemoteDocument:[error code] == 404 ? TICDSRemoteFileStructureDeletionResponseTypeNotDeleted : TICDSRemoteFileStructureDeletionResponseTypeError];
        return;
    }
    
    if( [path isEqualToString:[self clientDevicesDirectoryPath]] ) {
        [self fetchedListOfIdentifiersOfAllRegisteredClientsForThisApplication:nil];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSIntegrityKeyDirectoryName] ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
        [self fetchedRemoteIntegrityKey:nil];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentDeletedClientsDirectoryPath]] ) {
        [self discoveredDeletionStatusOfClient:[error code] == 404 ? TICDSRemoteFileStructureDeletionResponseTypeNotDeleted : TICDSRemoteFileStructureDeletionResponseTypeError];
        return;
    }
}

#pragma mark Directories
- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder
{
    NSString *path = [folder path];
    
    if( [path isEqualToString:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        _completedThisDocumentSyncChangesThisClientDirectory = YES;
        [self checkForThisDocumentClientDirectoryCompletion];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentSyncCommandsThisClientDirectoryPath]] ) {
        _completedThisDocumentSyncCommandsThisClientDirectory = YES;
        [self checkForThisDocumentClientDirectoryCompletion];
        return;
    }
    
    // if we get here, it's part of the document directory hierarchy
    _numberOfDocumentDirectoriesThatWereCreated++;
    [self checkForRemoteDocumentDirectoryCompletion];
}

- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [path isEqualToString:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        _completedThisDocumentSyncChangesThisClientDirectory = YES;
        _errorCreatingThisDocumentSyncChangesThisClientDirectory = YES;
        [self checkForThisDocumentClientDirectoryCompletion];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentSyncCommandsThisClientDirectoryPath]] ) {
        _completedThisDocumentSyncCommandsThisClientDirectory = YES;
        _errorCreatingThisDocumentSyncCommandsThisClientDirectory = YES;
        [self checkForThisDocumentClientDirectoryCompletion];
        return;
    }
    
    // if we get here, it's part of the document directory hierarchy
    _numberOfDocumentDirectoriesThatFailedToBeCreated++;
    [self checkForRemoteDocumentDirectoryCompletion];
}

#pragma mark Uploads
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
{
    if( [[destPath stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentDirectoryPath]] ) {
        [self savedRemoteDocumentInfoPlistWithSuccess:YES];
        return;
    }
    
    if( [[[destPath stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:TICDSIntegrityKeyDirectoryName] ) {
        [self savedIntegrityKeyWithSuccess:YES];
        return;
    }
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentDirectoryPath]] ) {
        [self savedRemoteDocumentInfoPlistWithSuccess:NO];
        return;
    }
    
    if( [[[path stringByDeletingLastPathComponent] lastPathComponent] isEqualToString:TICDSIntegrityKeyDirectoryName] ) {
        [self savedIntegrityKeyWithSuccess:NO];
        return;
    }
}

#pragma mark Deletion
- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
    if( [path isEqualToString:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:YES];
        return;
    }
    
    if( [[path pathExtension] isEqualToString:TICDSDeviceInfoPlistExtension] ) {
        [self deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:YES];
        return;
    }
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [path isEqualToString:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:NO];
        return;
    }
    
    if( [[path pathExtension] isEqualToString:TICDSDeviceInfoPlistFilename] ) {
        [self deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:NO];
        return;
    }
}

#pragma mark Copying
- (void)restClient:(DBRestClient*)client copiedPath:(NSString *)from_path toPath:(NSString *)to_path
{
    // should really check the paths, but there's only one copy procedure in this operation...
    [self addedDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:[[to_path lastPathComponent] stringByDeletingPathExtension] withSuccess:YES];
}

- (void)restClient:(DBRestClient*)client copyPathFailedWithError:(NSError*)error
{
    // should really check the paths, but there's only one copy procedure in this operation...
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    [self addedDeviceInfoPlistToDocumentDeletedClientsForClientWithIdentifier:[[path lastPathComponent] stringByDeletingPathExtension] withSuccess:NO];
}

#pragma mark -
#pragma mark Initialization and Deallocation


#if !__has_feature(objc_arc)

 - (void)dealloc
{
    [_restClient setDelegate:nil];

    _dbSession = nil;
    _restClient = nil;
    _documentsDirectoryPath = nil;
    _clientDevicesDirectoryPath = nil;
    _thisDocumentDirectoryPath = nil;
    _thisDocumentDeletedClientsDirectoryPath = nil;
    _deletedDocumentsDirectoryIdentifierPlistFilePath = nil;
    _thisDocumentSyncChangesThisClientDirectoryPath = nil;
    _thisDocumentSyncCommandsThisClientDirectoryPath = nil;
    
}
#endif


#pragma mark -
#pragma mark Lazy Accessors
- (DBRestClient *)restClient
{
    if( _restClient ) return _restClient;
    
    _restClient = [[DBRestClient alloc] initWithSession:[self dbSession]];
    [_restClient setDelegate:self];
    
    return _restClient;
}

#pragma mark -
#pragma mark Properties
@synthesize dbSession = _dbSession;
@synthesize restClient = _restClient;
@synthesize documentsDirectoryPath = _documentsDirectoryPath;
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize thisDocumentDirectoryPath = _thisDocumentDirectoryPath;
@synthesize thisDocumentDeletedClientsDirectoryPath = _thisDocumentDeletedClientsDirectoryPath;
@synthesize deletedDocumentsDirectoryIdentifierPlistFilePath = _deletedDocumentsDirectoryIdentifierPlistFilePath;
@synthesize thisDocumentSyncChangesThisClientDirectoryPath = _thisDocumentSyncChangesThisClientDirectoryPath;
@synthesize thisDocumentSyncCommandsThisClientDirectoryPath = _thisDocumentSyncCommandsThisClientDirectoryPath;

@end

#endif