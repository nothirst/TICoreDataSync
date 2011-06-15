//
//  TICDSDropboxSDKBasedDocumentClientDeletionOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 04/06/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"

@implementation TICDSDropboxSDKBasedDocumentClientDeletionOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)checkWhetherClientDirectoryExistsInDocumentSyncChangesDirectory
{
    [[self restClient] loadMetadata:[[self thisDocumentSyncChangesDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]]];
}

- (void)checkWhetherClientIdentifierFileAlreadyExistsInDocumentDeletedClientsDirectory
{
    [[self restClient] loadMetadata:[[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension]];
}

- (void)deleteClientIdentifierFileFromDeletedClientsDirectory
{
    [[self restClient] deletePath:[[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension]];
}

- (void)copyClientDeviceInfoPlistToDeletedClientsDirectory
{
    NSString *deviceInfoFilePath = [[[self clientDevicesDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension];
    
    NSString *finalFilePath = [[[self thisDocumentDeletedClientsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathExtension:TICDSDeviceInfoPlistExtension];
    
    [[self restClient] copyFrom:deviceInfoFilePath toPath:finalFilePath];
}

- (void)deleteClientDirectoryFromDocumentSyncChangesDirectory
{
    [[self restClient] deletePath:[[self thisDocumentSyncChangesDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]]];
}

- (void)deleteClientDirectoryFromDocumentSyncCommandsDirectory
{
    [[self restClient] deletePath:[[self thisDocumentSyncCommandsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]]];
}

- (void)checkWhetherClientIdentifierFileExistsInRecentSyncsDirectory
{
    [[self restClient] loadMetadata:[[[self thisDocumentRecentSyncsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathExtension:TICDSRecentSyncFileExtension]];
}

- (void)deleteClientIdentifierFileFromRecentSyncsDirectory
{
    [[self restClient] deletePath:[[[self thisDocumentRecentSyncsDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]] stringByAppendingPathExtension:TICDSRecentSyncFileExtension]];
}

- (void)checkWhetherClientDirectoryExistsInDocumentWholeStoreDirectory
{
    [[self restClient] loadMetadata:[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]]];
}

- (void)deleteClientDirectoryFromDocumentWholeStoreDirectory
{
    [[self restClient] deletePath:[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]]];
}

#pragma mark -
#pragma mark Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    NSString *path = [metadata path];
    TICDSRemoteFileStructureExistsResponseType status = [metadata isDeleted] ? TICDSRemoteFileStructureExistsResponseTypeDoesNotExist : TICDSRemoteFileStructureExistsResponseTypeDoesExist;
    
    if( [path isEqualToString:[[self thisDocumentSyncChangesDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]]] ) {
        [self discoveredStatusOfClientDirectoryInDocumentSyncChangesDirectory:status];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentDeletedClientsDirectoryPath]] ) {
        [self discoveredStatusOfClientIdentifierFileInDocumentDeletedClientsDirectory:status];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        [self discoveredStatusOfClientDirectoryInDocumentWholeStoreDirectory:status];
        return;
    }
    
    if( [[path pathExtension] isEqualToString:TICDSRecentSyncFileExtension] ) {
        [self discoveredStatusOfClientIdentifierFileInDocumentRecentSyncsDirectory:status];
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
    
    if( [path isEqualToString:[[self thisDocumentSyncChangesDirectoryPath] stringByAppendingPathComponent:[self identifierOfClientToBeDeleted]]] ) {
        [self discoveredStatusOfClientDirectoryInDocumentSyncChangesDirectory:status];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentDeletedClientsDirectoryPath]] ) {
        [self discoveredStatusOfClientIdentifierFileInDocumentDeletedClientsDirectory:status];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        [self discoveredStatusOfClientDirectoryInDocumentWholeStoreDirectory:status];
        return;
    }
    
    if( [[path pathExtension] isEqualToString:TICDSRecentSyncFileExtension] ) {
        [self discoveredStatusOfClientIdentifierFileInDocumentRecentSyncsDirectory:status];
        return;
    }
}

#pragma mark Deletion
- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentDeletedClientsDirectoryPath]] ) {
        [self deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:YES];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentSyncChangesDirectoryPath]] ) {
        [self deletedClientDirectoryFromDocumentSyncChangesDirectoryWithSuccess:YES];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentSyncCommandsDirectoryPath]] ) {
        [self deletedClientDirectoryFromDocumentSyncCommandsDirectoryWithSuccess:YES];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        [self deletedClientDirectoryFromDocumentWholeStoreDirectoryWithSuccess:YES];
        return;
    }
    
    if( [[path pathExtension] isEqualToString:TICDSRecentSyncFileExtension] ) {
        [self deletedClientIdentifierFileFromRecentSyncsDirectoryWithSuccess:YES];
        return;
    }
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentDeletedClientsDirectoryPath]] ) {
        [self deletedClientIdentifierFileFromDeletedClientsDirectoryWithSuccess:NO];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentSyncChangesDirectoryPath]] ) {
        [self deletedClientDirectoryFromDocumentSyncChangesDirectoryWithSuccess:NO];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentSyncCommandsDirectoryPath]] ) {
        [self deletedClientDirectoryFromDocumentSyncCommandsDirectoryWithSuccess:NO];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        [self deletedClientDirectoryFromDocumentWholeStoreDirectoryWithSuccess:NO];
        return;
    }
    
    if( [[path pathExtension] isEqualToString:TICDSRecentSyncFileExtension] ) {
        [self deletedClientIdentifierFileFromRecentSyncsDirectoryWithSuccess:NO];
        return;
    }
}

#pragma mark Copying
- (void)restClient:(DBRestClient*)client copiedPath:(NSString *)from_path toPath:(NSString *)to_path
{
    // should really check the paths, but there's only one copy procedure in this operation...
    [self copiedClientDeviceInfoPlistToDeletedClientsDirectoryWithSuccess:YES];
}

- (void)restClient:(DBRestClient*)client copyPathFailedWithError:(NSError*)error
{
    // should really check the paths, but there's only one copy procedure in this operation...
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    [self copiedClientDeviceInfoPlistToDeletedClientsDirectoryWithSuccess:NO];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_dbSession release], _dbSession = nil;
    [_restClient release], _restClient = nil;
    
    [_clientDevicesDirectoryPath release], _clientDevicesDirectoryPath = nil;
    [_thisDocumentDeletedClientsDirectoryPath release], _thisDocumentDeletedClientsDirectoryPath = nil;
    [_thisDocumentSyncChangesDirectoryPath release], _thisDocumentSyncChangesDirectoryPath = nil;
    [_thisDocumentSyncCommandsDirectoryPath release], _thisDocumentSyncCommandsDirectoryPath = nil;
    [_thisDocumentRecentSyncsDirectoryPath release], _thisDocumentRecentSyncsDirectoryPath = nil;
    [_thisDocumentWholeStoreDirectoryPath release], _thisDocumentWholeStoreDirectoryPath = nil;
    
    [super dealloc];
}

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
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize thisDocumentDeletedClientsDirectoryPath = _thisDocumentDeletedClientsDirectoryPath;
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;
@synthesize thisDocumentSyncCommandsDirectoryPath = _thisDocumentSyncCommandsDirectoryPath;
@synthesize thisDocumentRecentSyncsDirectoryPath = _thisDocumentRecentSyncsDirectoryPath;
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;

@end

#endif