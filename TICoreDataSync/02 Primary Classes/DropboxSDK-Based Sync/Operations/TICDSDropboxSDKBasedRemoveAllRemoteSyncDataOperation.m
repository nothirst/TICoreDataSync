//
//  TICDSDropboxSDKBasedRemoveAllRemoteSyncDataOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 05/08/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICoreDataSync.h"


@implementation TICDSDropboxSDKBasedRemoveAllRemoteSyncDataOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)removeRemoteSyncDataDirectory
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] deletePath:[self applicationDirectoryPath]];
}

#pragma mark - Rest Client Delegate
#pragma mark Deletion
- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif
    // Should really check the path, but this is the only deletion in this operation
    [self removedRemoteSyncDataDirectoryWithSuccess:YES];
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
    
    if( [error code] == 404 ) {
        // path didn't exist to delete, so deletion is 'complete'
        [self removedRemoteSyncDataDirectoryWithSuccess:YES];
        return;
    }
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    // Should really check the path, but this is the only deletion in this operation
    [self removedRemoteSyncDataDirectoryWithSuccess:NO];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    [_restClient setDelegate:nil];

    _restClient = nil;
    _applicationDirectoryPath = nil;
    
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
@synthesize applicationDirectoryPath = _applicationDirectoryPath;

@end

