//
//  TICDSDropboxSDKBasedWholeStoreUploadOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICoreDataSync.h"

@interface TICDSDropboxSDKBasedWholeStoreUploadOperation ()

@property (nonatomic, copy) NSString *wholeStoreFileParentRevision;
@property (nonatomic, copy) NSString *appliedSyncChangeSetsFileParentRevision;

- (void)uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:(NSString *)parentRevision;
- (void)uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:(NSString *)parentRevision;

@end


@implementation TICDSDropboxSDKBasedWholeStoreUploadOperation

#pragma mark - Overridden Methods
- (BOOL)needsMainThread
{
    return YES;
}

- (void)checkWhetherThisClientTemporaryWholeStoreDirectoryExists
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]];
}

- (void)deleteThisClientTemporaryWholeStoreDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] deletePath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]];
}

- (void)createThisClientTemporaryWholeStoreDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] createFolder:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]];
}

- (void)uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [self.restClient loadRevisionsForFile:[[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] stringByAppendingPathComponent:TICDSWholeStoreFilename] limit:1];
}

- (void)uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:(NSString *)parentRevision
{
    NSError *anyError = nil;
    BOOL success = YES;
    NSString *filePath = [[self localWholeStoreFileLocation] path];
    
    NSString *tempPath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:[filePath lastPathComponent]];

    if ( [self shouldUseCompressionForWholeStoreMoves] ) {
        
        // Create the zipped file
        NSString *zipFilePath = [tempPath stringByAppendingPathExtension:kSSZipArchiveFilenameSuffixForCompressedFile];
        success = [SSZipArchive createZipFileAtPath:zipFilePath withFilesAtPaths:[NSArray arrayWithObject:filePath]];
        
        if (!success) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeCompressionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
            return;
        }

        filePath = zipFilePath;
    }
    
    if( [self shouldUseEncryption] ) {
        
        success = [[self cryptor] encryptFileAtLocation:[NSURL fileURLWithPath:filePath] writingToLocation:[NSURL fileURLWithPath:tempPath] error:&anyError];
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
            return;
        }
        
        filePath = tempPath;
    }
    
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] uploadFile:TICDSWholeStoreFilename toPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] withParentRev:parentRevision fromPath:filePath];
}

- (void)uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [self.restClient loadRevisionsForFile:[[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename] limit:1];
}

- (void)uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:(NSString *)parentRevision
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] uploadFile:TICDSAppliedSyncChangeSetsFilename toPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] withParentRev:parentRevision fromPath:[[self localAppliedSyncChangeSetsFileLocation] path]];
}

- (void)checkWhetherThisClientWholeStoreDirectoryExists
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self thisDocumentWholeStoreThisClientDirectoryPath]];
}

- (void)deleteThisClientWholeStoreDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] deletePath:[self thisDocumentWholeStoreThisClientDirectoryPath]];
}

- (void)copyThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] copyFrom:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] toPath:[self thisDocumentWholeStoreThisClientDirectoryPath]];
}

#pragma mark - Rest Client Delegate

#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

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
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    NSString *path = [[error userInfo] valueForKey:@"path"];
    NSInteger errorCode = [error code];
    
    if (errorCode == 503) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@", path);
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [client loadMetadata:path];
        return;
    }
    
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
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    [self handleDeletionAtPath:path];
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    NSString *path = [[error userInfo] valueForKey:@"path"];
    NSInteger errorCode = [error code];
    
    if (errorCode == 503) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@", path);
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [client deletePath:path];
        return;
    }
    
    if (errorCode == 404) { // A file or folder does not exist at this location. We do not consider this case a failure.
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"DBRestClient reported that an object we asked it to delete did not exist. Treating this as a non-error.");
        [self handleDeletionAtPath:path];
        return;
    }
    
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

- (void)handleDeletionAtPath:(NSString *)path
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

#pragma mark Directories
- (void)restClient:(DBRestClient *)client createdFolder:(DBMetadata *)folder
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *path = [folder path];
    
    if( [path isEqualToString:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]] ) {
        [self createdThisClientTemporaryWholeStoreDirectoryWithSuccess:YES];
        return;
    }
}

- (void)restClient:(DBRestClient *)client createFolderFailedWithError:(NSError *)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *path = [[error userInfo] valueForKey:@"path"];
    NSInteger errorCode = [error code];
    
    if (errorCode == 503) { // Potentially bogus rate-limiting error code. Current advice from Dropbox is to retry immediately. --M.Fey, 2012-12-19
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@", path);
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [client createFolder:path];
        return;
    }
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [path isEqualToString:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]] ) {
        [self createdThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
        return;
    }
}

#pragma mark Revisions
- (void)restClient:(DBRestClient*)client loadedRevisions:(NSArray *)revisions forFile:(NSString *)path
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    NSString *parentRevision = nil;
    if ([revisions count] > 0) {
        parentRevision = [[revisions objectAtIndex:0] rev];
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        self.wholeStoreFileParentRevision = parentRevision;
        [self uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:self.wholeStoreFileParentRevision];
        return;
    }

    if( [[path lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        self.appliedSyncChangeSetsFileParentRevision = parentRevision;
        [self uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:self.appliedSyncChangeSetsFileParentRevision];
        return;
    }
}

- (void)restClient:(DBRestClient*)client loadRevisionsFailedWithError:(NSError *)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    // A failure in this case could be caused by the file not existing, so we attempt to upload the file with no parent revision. That, of course, has its own failure checks.
    NSString *path = [[error userInfo] valueForKey:@"path"];
    NSInteger errorCode = error.code;
    
    if (errorCode == 503) { // Potentially bogus rate-limiting error code. Current advice from Dropbox is to retry immediately. --M.Fey, 2012-12-19
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@", path);
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [client loadRevisionsForFile:path limit:1];
        return;
    }

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
-(void)restClient:(DBRestClient *)client uploadedFile:(NSString *)destPath from:(NSString *)srcPath
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    if( [[destPath lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:YES];
        return;
    }
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        [self uploadedAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:YES];
        return;
    }
}

- (void)restClient:(DBRestClient*)client uploadProgress:(CGFloat)progress forFile:(NSString*)destPath from:(NSString*)srcPath
{
    [self setProgress:progress];
    if( [[destPath lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        
        [self uploadingWholeStoreFileToThisClientTemporaryWholeStoreDirectoryMadeProgress];
        return;
    }
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        [self uploadingLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryMadeProgress];
        return;
    }
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    NSString *path = [[error userInfo] valueForKey:@"destinationPath"];
    NSInteger errorCode = error.code;
    
    if (errorCode == 503) { // Potentially bogus rate-limiting error code. Current advice from Dropbox is to retry immediately. --M.Fey, 2012-12-19
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@", path);
        if( [[path lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
            [self uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:self.wholeStoreFileParentRevision];
            return;
        }
        
        if( [[path lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
            [self uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithParentRevision:self.appliedSyncChangeSetsFileParentRevision];
            return;
        }
    }
    
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

- (void)restClient:(DBRestClient*)client copiedPath:(NSString *)fromPath to:(DBMetadata *)toPath
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    NSLog(@"%s", __PRETTY_FUNCTION__);
    // should really check the paths, but there's only one copy procedure in this operation...
    [self copiedThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectoryWithSuccess:YES];
}

- (void)restClient:(DBRestClient*)client copyPathFailedWithError:(NSError*)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSString *sourcePath = [error.userInfo objectForKey:@"from_path"];
    NSString *destinationPath = [error.userInfo objectForKey:@"to_path"];
    NSInteger errorCode = error.code;
    
    if (errorCode == 503) {
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@ to %@", sourcePath, destinationPath);
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [client copyFrom:sourcePath toPath:destinationPath];
        return;
    }
    
    // should really check the paths, but there's only one copy procedure in this operation...
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    [self copiedThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectoryWithSuccess:NO];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    [_restClient setDelegate:nil];

    _restClient = nil;
    
    _thisDocumentTemporaryWholeStoreThisClientDirectoryPath = nil;
    _thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath = nil;
    _thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = nil;
    _thisDocumentWholeStoreThisClientDirectoryPath = nil;

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
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryPath = _thisDocumentTemporaryWholeStoreThisClientDirectoryPath;
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath = _thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath;
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = _thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;
@synthesize thisDocumentWholeStoreThisClientDirectoryPath = _thisDocumentWholeStoreThisClientDirectoryPath;

@end

