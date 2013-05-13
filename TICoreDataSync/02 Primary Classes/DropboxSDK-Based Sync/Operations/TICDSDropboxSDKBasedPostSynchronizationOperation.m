//
//  TICDSDropboxSDKBasedPostSynchronizationOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICoreDataSync.h"

@interface TICDSDropboxSDKBasedPostSynchronizationOperation ()

/** When we fail to download a changeset file we re-request it and put its path in this set so that we can keep track of the fact that we've re-requested it. */
@property (nonatomic, strong) NSMutableDictionary *failedDownloadRetryDictionary;

/** When uploading the local sync changes we need to first ask the Dropbox for any parent revisions. We store off the file path of the file we intend to upload while we get its revisions. */
@property (nonatomic, copy) NSString *localSyncChangeSetFilePath;

/** When uploading recent sync files we need to first ask the Dropbox for any parent revisions. We store off the file path of the file we intend to upload while we get its revisions. */
@property (nonatomic, copy) NSString *recentSyncFilePath;

@property (nonatomic, copy) NSString *localSyncChangeSetFileParentRevision;
@property (nonatomic, copy) NSString *recentSyncFileParentRevision;

- (void)uploadLocalSyncChangeSetFileWithParentRevision:(NSString *)parentRevision;
- (void)uploadRecentSyncFileWithParentRevision:(NSString *)parentRevision;

@end

@implementation TICDSDropboxSDKBasedPostSynchronizationOperation

#pragma mark - Overridden Methods
- (BOOL)needsMainThread
{
    return YES;
}

#pragma mark Uploading Change Sets
- (void)uploadLocalSyncChangeSetFileAtLocation:(NSURL *)aLocation
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    NSString *finalFilePath = [aLocation path];
    
    if( [self shouldUseEncryption] ) {
        NSString *tempFilePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:[finalFilePath lastPathComponent]];
        
        NSError *anyError = nil;
        BOOL success = [[self cryptor] encryptFileAtLocation:aLocation writingToLocation:[NSURL fileURLWithPath:tempFilePath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self uploadedLocalSyncChangeSetFileSuccessfully:NO];
            return;
        }
        
        finalFilePath = tempFilePath;
    }
    
    self.localSyncChangeSetFilePath = finalFilePath;
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [self.restClient loadRevisionsForFile:[[self thisDocumentSyncChangesThisClientDirectoryPath] stringByAppendingPathComponent:[finalFilePath lastPathComponent]] limit:1];
}

- (void)uploadLocalSyncChangeSetFileWithParentRevision:(NSString *)parentRevision
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] uploadFile:[self.localSyncChangeSetFilePath lastPathComponent] toPath:[self thisDocumentSyncChangesThisClientDirectoryPath] withParentRev:parentRevision fromPath:self.localSyncChangeSetFilePath];
}

#pragma mark Uploading Recent Sync File
- (void)uploadRecentSyncFileAtLocation:(NSURL *)aLocation
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    self.recentSyncFilePath = [aLocation path];
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [self.restClient loadRevisionsForFile:[[[self thisDocumentRecentSyncsThisClientFilePath] stringByDeletingLastPathComponent] stringByAppendingPathComponent:[[aLocation path] lastPathComponent]] limit:1];
}

- (void)uploadRecentSyncFileWithParentRevision:(NSString *)parentRevision
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] uploadFile:[self.recentSyncFilePath lastPathComponent] toPath:[[self thisDocumentRecentSyncsThisClientFilePath] stringByDeletingLastPathComponent] withParentRev:parentRevision fromPath:self.recentSyncFilePath];
}

#pragma mark - Rest Client Delegate

#pragma mark Revisions
- (void)restClient:(DBRestClient*)client loadedRevisions:(NSArray *)revisions forFile:(NSString *)path
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if (path != nil) {
        [self.failedDownloadRetryDictionary removeObjectForKey:path];
    }

    NSString *parentRevision = nil;
    if ([revisions count] > 0) {
        parentRevision = [[revisions objectAtIndex:0] rev];
    }
    
    if( [[path lastPathComponent] isEqualToString:[self.localSyncChangeSetFilePath lastPathComponent]] ) {
        self.localSyncChangeSetFileParentRevision = parentRevision;
        [self uploadLocalSyncChangeSetFileWithParentRevision:parentRevision];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:[self.recentSyncFilePath lastPathComponent]] ) {
        self.recentSyncFileParentRevision = parentRevision;
        [self uploadRecentSyncFileWithParentRevision:parentRevision];
        return;
    }
}

- (void)restClient:(DBRestClient*)client loadRevisionsFailedWithError:(NSError *)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    NSString *destPath = [[error userInfo] valueForKey:@"path"];
    NSInteger errorCode = error.code;
    
    if (errorCode == 503) { // Potentially bogus rate-limiting error code. Current advice from Dropbox is to retry immediately. --M.Fey, 2012-12-19
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@", destPath);
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [client loadRevisionsForFile:destPath limit:1];
        return;
    }

    NSInteger retryCount = 0;
    if (destPath != nil && errorCode != 404 && [[self.failedDownloadRetryDictionary objectForKey:destPath] integerValue] < 5) {
        retryCount = [[self.failedDownloadRetryDictionary objectForKey:destPath] integerValue];
        retryCount++;
        TICDSLog(TICDSLogVerbosityEveryStep, @"Failed to load revisions for %@. Going for try number %ld", destPath, (long)retryCount);
        [self.failedDownloadRetryDictionary setObject:[NSNumber numberWithInteger:retryCount] forKey:destPath];
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [self.restClient loadRevisionsForFile:destPath limit:1];
        return;
    }
    
    if (destPath != nil) {
        [self.failedDownloadRetryDictionary removeObjectForKey:destPath];
    }

    if (retryCount >= 5) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"Failed to load revisions of %@ after 5 attempts, we're falling through to the error condition.", destPath);
    } else if (errorCode == 404) {
        TICDSLog(TICDSLogVerbosityEveryStep, @"No previous revisions of %@ exist, uploading with no parent revision.", destPath);
    }

    // A failure in this case could be caused by the file not existing, so we attempt to upload the file with no parent revision. That, of course, has its own failure checks.
    
    if( [[[destPath lastPathComponent] pathExtension] isEqualToString:TICDSSyncChangeSetFileExtension] ) {
        [self uploadLocalSyncChangeSetFileWithParentRevision:nil];
        return;
    }
    
    if( [destPath isEqualToString:[self thisDocumentRecentSyncsThisClientFilePath]] ) {
        [self uploadRecentSyncFileWithParentRevision:nil];
        return;
    }
    
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Didn't catch the fact that we failed to load revisions for %@", destPath);
    [self operationDidFailToComplete];
}

#pragma mark Uploads
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath from:(NSString*)srcPath
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if( [[[destPath lastPathComponent] pathExtension] isEqualToString:TICDSSyncChangeSetFileExtension] ) {
        [self uploadedLocalSyncChangeSetFileSuccessfully:YES];
        return;
    }
    
    if( [destPath isEqualToString:[self thisDocumentRecentSyncsThisClientFilePath]] ) {
        [self uploadedRecentSyncFileSuccessfully:YES];
        return;
    }
}

- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    NSString *path = [[error userInfo] valueForKey:@"destinationPath"];
    NSInteger errorCode = error.code;
    
    if (errorCode == 503) { // Potentially bogus rate-limiting error code. Current advice from Dropbox is to retry immediately. --M.Fey, 2012-12-19
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@", path);
        if ( [[path lastPathComponent] isEqualToString:[self.localSyncChangeSetFilePath lastPathComponent]] ) {
            [self uploadLocalSyncChangeSetFileWithParentRevision:self.localSyncChangeSetFileParentRevision];
            return;
        }
        
        if ( [[path lastPathComponent] isEqualToString:[self.recentSyncFilePath lastPathComponent]] ) {
            [self uploadRecentSyncFileWithParentRevision:self.recentSyncFileParentRevision];
            return;
        }
    }
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [[[path lastPathComponent] pathExtension] isEqualToString:TICDSSyncChangeSetFileExtension] ) {
        [self uploadedLocalSyncChangeSetFileSuccessfully:NO];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentRecentSyncsThisClientFilePath]] ) {
        [self uploadedRecentSyncFileSuccessfully:NO];
        return;
    }
 
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an upload failure that we're not handling properly for the file located at %@", path);
    [self operationDidFailToComplete];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    [_restClient setDelegate:nil];

    _restClient = nil;
    _thisDocumentSyncChangesDirectoryPath = nil;
    _thisDocumentSyncChangesThisClientDirectoryPath = nil;
    _thisDocumentRecentSyncsThisClientFilePath = nil;

}

#pragma mark - Lazy Accessors
- (DBRestClient *)restClient
{
    if( _restClient ) return _restClient;
    
    _restClient = [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
    [_restClient setDelegate:self];
    
    return _restClient;
}

- (NSMutableDictionary *)failedDownloadRetryDictionary
{
    if (_failedDownloadRetryDictionary == nil) {
        _failedDownloadRetryDictionary = [[NSMutableDictionary alloc] init];
    }
    
    return _failedDownloadRetryDictionary;
}

#pragma mark - Properties
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;
@synthesize thisDocumentSyncChangesThisClientDirectoryPath = _thisDocumentSyncChangesThisClientDirectoryPath;
@synthesize thisDocumentRecentSyncsThisClientFilePath = _thisDocumentRecentSyncsThisClientFilePath;
@synthesize failedDownloadRetryDictionary = _failedDownloadRetryDictionary;
@synthesize localSyncChangeSetFilePath = _localSyncChangeSetFilePath;
@synthesize recentSyncFilePath = _recentSyncFilePath;
@synthesize restClient = _restClient;
@end

