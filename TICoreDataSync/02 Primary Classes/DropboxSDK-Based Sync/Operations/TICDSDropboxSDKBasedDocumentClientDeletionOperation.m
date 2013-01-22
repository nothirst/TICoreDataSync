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

#pragma mark - Rest Client Delegate
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

    if (errorCode == 503) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@", path);
        [client loadMetadata:path];
        return;
    }
    
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
    [self handleDeletionAtPath:path];
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    NSInteger errorCode = [error code];
    
    if (errorCode == 503) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@", path);
        [client deletePath:path];
        return;
    }
    
    if (errorCode == 404) { // A file or folder does not exist at this location. We do not consider this case a failure.
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"DBRestClient reported that an object we asked it to delete did not exist. Treating this as a non-error.");
        [self handleDeletionAtPath:path];
        return;
    }

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

- (void)handleDeletionAtPath:(NSString *)path
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

#pragma mark Copying
- (void)restClient:(DBRestClient*)client copiedPath:(NSString *)fromPath to:(NSString *)toPath
{
    // should really check the paths, but there's only one copy procedure in this operation...
    [self copiedClientDeviceInfoPlistToDeletedClientsDirectoryWithSuccess:YES];
}

- (void)restClient:(DBRestClient*)client copyPathFailedWithError:(NSError*)error
{
    NSString *sourcePath = [error.userInfo objectForKey:@"from_path"];
    NSString *destinationPath = [error.userInfo objectForKey:@"to_path"];
    NSInteger errorCode = error.code;
    
    if (errorCode == 503) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@ to %@", sourcePath, destinationPath);
        [client copyFrom:sourcePath toPath:destinationPath];
        return;
    }
    
    // should really check the paths, but there's only one copy procedure in this operation...
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    [self copiedClientDeviceInfoPlistToDeletedClientsDirectoryWithSuccess:NO];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    [_restClient setDelegate:nil];

    _restClient = nil;
    
    _clientDevicesDirectoryPath = nil;
    _thisDocumentDeletedClientsDirectoryPath = nil;
    _thisDocumentSyncChangesDirectoryPath = nil;
    _thisDocumentSyncCommandsDirectoryPath = nil;
    _thisDocumentRecentSyncsDirectoryPath = nil;
    _thisDocumentWholeStoreDirectoryPath = nil;
    
}

#pragma mark - Lazy Accessors
- (DBRestClient *)restClient
{
    if( _restClient ) return _restClient;
    
    _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    [_restClient setDelegate:self];
    
    return _restClient;
}

#pragma mark - Properties
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize thisDocumentDeletedClientsDirectoryPath = _thisDocumentDeletedClientsDirectoryPath;
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;
@synthesize thisDocumentSyncCommandsDirectoryPath = _thisDocumentSyncCommandsDirectoryPath;
@synthesize thisDocumentRecentSyncsDirectoryPath = _thisDocumentRecentSyncsDirectoryPath;
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;

@end

#endif
