//
//  TICDSDropboxSDKBasedRemoveAllRemoteSyncDataOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 05/08/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"


@implementation TICDSDropboxSDKBasedRemoveAllRemoteSyncDataOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)removeRemoteSyncDataDirectory
{
    [[self restClient] deletePath:[self applicationDirectoryPath]];
}

#pragma mark -
#pragma mark Rest Client Delegate
#pragma mark Deletion
- (void)restClient:(DBRestClient*)client deletedPath:(NSString *)path
{
    // Should really check the path, but this is the only deletion in this operation
    [self removedRemoteSyncDataDirectoryWithSuccess:YES];
}

- (void)restClient:(DBRestClient*)client deletePathFailedWithError:(NSError*)error
{
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    // Should really check the path, but this is the only deletion in this operation
    [self removedRemoteSyncDataDirectoryWithSuccess:NO];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_dbSession release], _dbSession = nil;
    [_restClient release], _restClient = nil;
    [_applicationDirectoryPath release], _applicationDirectoryPath = nil;
    
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
@synthesize applicationDirectoryPath = _applicationDirectoryPath;

@end

#endif