//
//  TICDSDropboxSDKBasedWholeStoreUploadOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSDropboxSDKBasedWholeStoreUploadOperation

#pragma mark -
#pragma mark Overridden Methods
- (BOOL)needsMainThread
{
    return YES;
}

#pragma mark Directories
- (void)checkWhetherThisClientWholeStoreDirectoryExists
{
    [[self restClient] loadMetadata:[self thisDocumentWholeStoreThisClientDirectoryPath]];
}

- (void)createThisClientWholeStoreDirectory
{
    [[self restClient] createFolder:[self thisDocumentWholeStoreThisClientDirectoryPath]];
}

#pragma mark Whole Store
- (void)uploadWholeStoreFile
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    NSString *finalFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSWholeStoreFilename];
    
    if( [self shouldUseEncryption] ) {
        success = [[self cryptor] encryptFileAtLocation:[self localWholeStoreFileLocation] writingToLocation:[NSURL fileURLWithPath:finalFilePath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self uploadedWholeStoreFileWithSuccess:NO];
            return;
        }
    }
    
    [[self restClient] uploadFile:TICDSWholeStoreFilename toPath:[self thisDocumentWholeStoreThisClientDirectoryPath] fromPath:finalFilePath];
}

#pragma mark Applied Sync Changes
- (void)uploadAppliedSyncChangeSetsFile
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    NSString *finalFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename];
    
    if( [self shouldUseEncryption] ) {
        success = [[self cryptor] encryptFileAtLocation:[self localAppliedSyncChangeSetsFileLocation] writingToLocation:[NSURL fileURLWithPath:finalFilePath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self uploadedAppliedSyncChangeSetsFileWithSuccess:NO];
            return;
        }
    }
    
    [[self restClient] uploadFile:TICDSAppliedSyncChangeSetsFilename toPath:[self thisDocumentWholeStoreThisClientDirectoryPath] fromPath:finalFilePath];
}

#pragma mark -
#pragma mark Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    NSString *path = [metadata path];
    TICDSRemoteFileStructureExistsResponseType status = [metadata isDeleted] ? TICDSRemoteFileStructureExistsResponseTypeDoesNotExist : TICDSRemoteFileStructureExistsResponseTypeDoesExist;
    
    if( [path isEqualToString:[self thisDocumentWholeStoreThisClientDirectoryPath]] ) {
        [self discoveredStatusOfWholeStoreDirectory:status];
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
    
    if( [path isEqualToString:[self thisDocumentWholeStoreThisClientDirectoryPath]] ) {
        [self discoveredStatusOfWholeStoreDirectory:status];
        return;
    }
}

#pragma mark Directories
- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder
{
    NSString *path = [folder path];
    
    if( [path isEqualToString:[self thisDocumentWholeStoreThisClientDirectoryPath]] ) {
        [self createdThisClientWholeStoreDirectorySuccessfully:YES];
        return;
    }
}

- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [path isEqualToString:[self thisDocumentWholeStoreThisClientDirectoryPath]] ) {
        [self createdThisClientWholeStoreDirectorySuccessfully:NO];
        return;
    }
}

#pragma mark Uploads
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
{
    if( [[destPath lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        [self uploadedWholeStoreFileWithSuccess:YES];
        return;
    }
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        [self uploadedAppliedSyncChangeSetsFileWithSuccess:YES];
        return;
    }
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [[path lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        [self uploadedWholeStoreFileWithSuccess:NO];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        [self uploadedAppliedSyncChangeSetsFileWithSuccess:NO];
        return;
    }
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_dbSession release], _dbSession = nil;
    [_restClient release], _restClient = nil;
    
    [_thisDocumentWholeStoreThisClientDirectoryPath release], _thisDocumentWholeStoreThisClientDirectoryPath = nil;
    [_thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath release], _thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath = nil;
    [_thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath release], _thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = nil;
    
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
@synthesize thisDocumentWholeStoreThisClientDirectoryPath = _thisDocumentWholeStoreThisClientDirectoryPath;
@synthesize thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath = _thisDocumentWholeStoreThisClientDirectoryWholeStoreFilePath;
@synthesize thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = _thisDocumentWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;

@end
