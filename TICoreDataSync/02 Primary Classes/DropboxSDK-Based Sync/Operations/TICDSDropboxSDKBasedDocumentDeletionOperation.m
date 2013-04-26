//
//  TICDSDropboxSDKBasedDocumentDeletionOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"

@implementation TICDSDropboxSDKBasedDocumentDeletionOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)checkWhetherIdentifiedDocumentDirectoryExists
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self documentDirectoryPath]];
}

- (void)checkForExistingIdentifierPlistInDeletedDocumentsDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self deletedDocumentsDirectoryIdentifierPlistFilePath]];
}

- (void)deleteDocumentInfoPlistFromDeletedDocumentsDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] deletePath:[self deletedDocumentsDirectoryIdentifierPlistFilePath]];
}

- (void)copyDocumentInfoPlistToDeletedDocumentsDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] copyFrom:[self documentInfoPlistFilePath] toPath:[self deletedDocumentsDirectoryIdentifierPlistFilePath]];
}

- (void)deleteDocumentDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] deletePath:[self documentDirectoryPath]];
}

#pragma mark - Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    NSString *path = [metadata path];
    
    if( [path isEqualToString:[self documentDirectoryPath]] ) {
        if (metadata.isDeleted == NO) {
            [self discoveredStatusOfIdentifiedDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesExist];
        } else {
            [self discoveredStatusOfIdentifiedDocumentDirectory:TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        }
        
        return;
    }
    
    if( [path isEqualToString:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self discoveredStatusOfIdentifierPlistInDeletedDocumentsDirectory:![metadata isDeleted] ? TICDSRemoteFileStructureExistsResponseTypeDoesExist : TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
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

    if( [error code] != 404 ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    if( [path isEqualToString:[self documentDirectoryPath]] ) {
        [self discoveredStatusOfIdentifiedDocumentDirectory:[error code] == 404 ? TICDSRemoteFileStructureExistsResponseTypeDoesNotExist : TICDSRemoteFileStructureExistsResponseTypeError];
        return;
    }
    
    if( [path isEqualToString:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self discoveredStatusOfIdentifierPlistInDeletedDocumentsDirectory:[error code] == 404 ? TICDSRemoteFileStructureExistsResponseTypeDoesNotExist : TICDSRemoteFileStructureExistsResponseTypeError];
        return;
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
    
    if( [path isEqualToString:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:NO];
        return;
    }
    
    if( [path isEqualToString:[self documentDirectoryPath]] ) {
        [self deletedDocumentDirectoryWithSuccess:NO];
        return;
    }
}

- (void)handleDeletionAtPath:(NSString *)path
{
    if( [path isEqualToString:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:YES];
        return;
    }
    
    if( [path isEqualToString:[self documentDirectoryPath]] ) {
        [self deletedDocumentDirectoryWithSuccess:YES];
        return;
    }
}

#pragma mark Copying
- (void)restClient:(DBRestClient*)client copiedPath:(NSString *)froPath to:(NSString *)toPath
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    // should really check the paths, but there's only one copy procedure in this operation...
    [self copiedDocumentInfoPlistToDeletedDocumentsDirectoryWithSuccess:YES];
}

- (void)restClient:(DBRestClient*)client copyPathFailedWithError:(NSError*)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

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
    
    [self copiedDocumentInfoPlistToDeletedDocumentsDirectoryWithSuccess:NO];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    [_restClient setDelegate:nil];

    _restClient = nil;
    _documentDirectoryPath = nil;
    _documentInfoPlistFilePath = nil;
    _deletedDocumentsDirectoryIdentifierPlistFilePath = nil;

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
@synthesize documentDirectoryPath = _documentDirectoryPath;
@synthesize documentInfoPlistFilePath = _documentInfoPlistFilePath;
@synthesize deletedDocumentsDirectoryIdentifierPlistFilePath = _deletedDocumentsDirectoryIdentifierPlistFilePath;

@end

