//
//  TICDSDropboxSDKBasedWholeStoreUploadOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"

@interface TICDSDropboxSDKBasedWholeStoreUploadOperation ()

- (void)uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:(NSString *)parentRevision;
- (void)uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:(NSString *)parentRevision;

@end


@implementation TICDSDropboxSDKBasedWholeStoreUploadOperation

#pragma mark -
#pragma mark Overridden Methods
- (BOOL)needsMainThread
{
    return YES;
}

- (void)checkWhetherThisClientTemporaryWholeStoreDirectoryExists
{
    [[self restClient] loadMetadata:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]];
}

- (void)deleteThisClientTemporaryWholeStoreDirectory
{
    [[self restClient] deletePath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]];
}

- (void)createThisClientTemporaryWholeStoreDirectory
{
    [[self restClient] createFolder:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]];
}

- (void)uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectory
{
    [self.restClient loadRevisionsForFile:[[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] stringByAppendingPathComponent:TICDSWholeStoreFilename] limit:1];
}

- (void)uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:(NSString *)parentRevision
{
    NSError *anyError = nil;
    BOOL success = YES;
    NSString *filePath = [[self localWholeStoreFileLocation] path];
    
    if( [self shouldUseEncryption] ) {
        NSString *tempPath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:[filePath lastPathComponent]];
        
        success = [[self cryptor] encryptFileAtLocation:[NSURL fileURLWithPath:filePath] writingToLocation:[NSURL fileURLWithPath:tempPath] error:&anyError];
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
            return;
        }
        
        filePath = tempPath;
    }
    
    [[self restClient] uploadFile:TICDSWholeStoreFilename toPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] withParentRev:parentRevision fromPath:filePath];
}

- (void)uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectory
{
    [self.restClient loadRevisionsForFile:[[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename] limit:1];
}

- (void)uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:(NSString *)parentRevision
{
    [[self restClient] uploadFile:TICDSAppliedSyncChangeSetsFilename toPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] withParentRev:parentRevision fromPath:[[self localAppliedSyncChangeSetsFileLocation] path]];
}

- (void)checkWhetherThisClientWholeStoreDirectoryExists
{
    [[self restClient] loadMetadata:[self thisDocumentWholeStoreThisClientDirectoryPath]];
}

- (void)deleteThisClientWholeStoreDirectory
{
    [[self restClient] deletePath:[self thisDocumentWholeStoreThisClientDirectoryPath]];
}

- (void)copyThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory
{
    [[self restClient] copyFrom:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] toPath:[self thisDocumentWholeStoreThisClientDirectoryPath]];
}

#pragma mark -
#pragma mark Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    NSString *path = [metadata path];
    TICDSRemoteFileStructureExistsResponseType status = [metadata isDeleted] ? TICDSRemoteFileStructureExistsResponseTypeDoesNotExist : TICDSRemoteFileStructureExistsResponseTypeDoesExist;
    
    if( [path isEqualToString:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]] ) {
        [self discoveredStatusOfThisClientTemporaryWholeStoreDirectory:status];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentWholeStoreThisClientDirectoryPath]] ) {
        [self discoveredStatusOfThisClientWholeStoreDirectory:status];
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
    
    if( [path isEqualToString:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]] ) {
        [self discoveredStatusOfThisClientTemporaryWholeStoreDirectory:status];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentWholeStoreThisClientDirectoryPath]] ) {
        [self discoveredStatusOfThisClientWholeStoreDirectory:status];
    }
}

#pragma mark Deletion
- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
    if( [path isEqualToString:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]] ) {
        [self deletedThisClientTemporaryWholeStoreDirectoryWithSuccess:YES];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentWholeStoreThisClientDirectoryPath]] ) {
        [self deletedThisClientWholeStoreDirectoryWithSuccess:YES];
        return;
    }
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    if( [path isEqualToString:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]] ) {
        [self deletedThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentWholeStoreThisClientDirectoryPath]] ) {
        [self deletedThisClientWholeStoreDirectoryWithSuccess:NO];
        return;
    }
}

#pragma mark Directories
- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder
{
    NSString *path = [folder path];
    
    if( [path isEqualToString:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]] ) {
        [self createdThisClientTemporaryWholeStoreDirectoryWithSuccess:YES];
        return;
    }
}

- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [path isEqualToString:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]] ) {
        [self createdThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
        return;
    }
}

#pragma mark Revisions
- (void)restClient:(DBRestClient*)client loadedRevisions:(NSArray *)revisions forFile:(NSString *)path
{
    NSString *parentRevision = nil;
    if ([revisions count] > 0) {
        parentRevision = [[revisions objectAtIndex:0] rev];
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        [self uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:parentRevision];
        return;
    }

    if( [[path lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        [self uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:parentRevision];
        return;
    }
}

- (void)restClient:(DBRestClient*)client loadRevisionsFailedWithError:(NSError *)error
{
    // A failure in this case could be caused by the file not existing, so we attempt to upload the file with no parent revision. That, of course, has its own failure checks.
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    if( [[path lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        [self uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:nil];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        [self uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:nil];
        return;
    }
}

#pragma mark Uploads
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
{
    if( [[destPath lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:YES];
        return;
    }
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        [self uploadedAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:YES];
        return;
    }
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [[path lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        [self uploadedAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
        return;
    }
}

#pragma mark Copying
- (void)restClient:(DBRestClient*)client copiedPath:(NSString *)from_path toPath:(NSString *)to_path
{
    // should really check the paths, but there's only one copy procedure in this operation...
    [self copiedThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectoryWithSuccess:YES];
}

- (void)restClient:(DBRestClient*)client copyPathFailedWithError:(NSError*)error
{
    // should really check the paths, but there's only one copy procedure in this operation...
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    [self copiedThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectoryWithSuccess:NO];
}

#pragma mark -
#pragma mark Initialization and Deallocation

#if !__has_feature(objc_arc)

 - (void)dealloc
{
    [_restClient setDelegate:nil];

    _dbSession = nil;
    _restClient = nil;
    
    _thisDocumentTemporaryWholeStoreThisClientDirectoryPath = nil;
    _thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath = nil;
    _thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = nil;
    _thisDocumentWholeStoreThisClientDirectoryPath = nil;

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
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryPath = _thisDocumentTemporaryWholeStoreThisClientDirectoryPath;
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath = _thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath;
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = _thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;
@synthesize thisDocumentWholeStoreThisClientDirectoryPath = _thisDocumentWholeStoreThisClientDirectoryPath;

@end

#endif