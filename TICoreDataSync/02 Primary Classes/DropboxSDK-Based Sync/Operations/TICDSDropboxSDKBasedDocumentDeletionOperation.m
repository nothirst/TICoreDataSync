//
//  TICDSDropboxSDKBasedDocumentDeletionOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 29/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"

@implementation TICDSDropboxSDKBasedDocumentDeletionOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)checkWhetherIdentifiedDocumentDirectoryExists
{
    [[self restClient] loadMetadata:[self documentDirectoryPath]];
}

- (void)checkForExistingIdentifierPlistInDeletedDocumentsDirectory
{
    [[self restClient] loadMetadata:[self deletedDocumentsDirectoryIdentifierPlistFilePath]];
}

- (void)deleteDocumentInfoPlistFromDeletedDocumentsDirectory
{
    [[self restClient] deletePath:[self deletedDocumentsDirectoryIdentifierPlistFilePath]];
}

- (void)copyDocumentInfoPlistToDeletedDocumentsDirectory
{
    [[self restClient] copyFrom:[self documentInfoPlistFilePath] toPath:[self deletedDocumentsDirectoryIdentifierPlistFilePath]];
}

- (void)deleteDocumentDirectory
{
    [[self restClient] deletePath:[self documentDirectoryPath]];
}

#pragma mark -
#pragma mark Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    NSString *path = [metadata path];
    
    if( [path isEqualToString:[self documentDirectoryPath]] ) {
        [self discoveredStatusOfIdentifiedDocumentDirectory:![metadata isDeleted] ? TICDSRemoteFileStructureExistsResponseTypeDoesExist : TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        
        return;
    }
    
    if( [path isEqualToString:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self discoveredStatusOfIdentifierPlistInDeletedDocumentsDirectory:![metadata isDeleted] ? TICDSRemoteFileStructureExistsResponseTypeDoesExist : TICDSRemoteFileStructureExistsResponseTypeDoesNotExist];
        return;
    }
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path
{
    
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
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
    if( [path isEqualToString:[self deletedDocumentsDirectoryIdentifierPlistFilePath]] ) {
        [self deletedDocumentInfoPlistFromDeletedDocumentsDirectoryWithSuccess:YES];
        return;
    }
    
    if( [path isEqualToString:[self documentDirectoryPath]] ) {
        [self deletedDocumentDirectoryWithSuccess:YES];
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
    
    if( [path isEqualToString:[self documentDirectoryPath]] ) {
        [self deletedDocumentDirectoryWithSuccess:NO];
        return;
    }
}

#pragma mark Copying
- (void)restClient:(DBRestClient*)client copiedPath:(NSString *)from_path toPath:(NSString *)to_path
{
    // should really check the paths, but there's only one copy procedure in this operation...
    [self copiedDocumentInfoPlistToDeletedDocumentsDirectoryWithSuccess:YES];
}

- (void)restClient:(DBRestClient*)client copyPathFailedWithError:(NSError*)error
{
    // should really check the paths, but there's only one copy procedure in this operation...
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    [self copiedDocumentInfoPlistToDeletedDocumentsDirectoryWithSuccess:NO];
}

#pragma mark -
#pragma mark Initialization and Deallocation


#if !__has_feature(objc_arc)

- (void)dealloc
{
    [_restClient setDelegate:nil];

    _dbSession = nil;
    _restClient = nil;
    _documentDirectoryPath = nil;
    _documentInfoPlistFilePath = nil;
    _deletedDocumentsDirectoryIdentifierPlistFilePath = nil;

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
@synthesize documentDirectoryPath = _documentDirectoryPath;
@synthesize documentInfoPlistFilePath = _documentInfoPlistFilePath;
@synthesize deletedDocumentsDirectoryIdentifierPlistFilePath = _deletedDocumentsDirectoryIdentifierPlistFilePath;

@end

#endif