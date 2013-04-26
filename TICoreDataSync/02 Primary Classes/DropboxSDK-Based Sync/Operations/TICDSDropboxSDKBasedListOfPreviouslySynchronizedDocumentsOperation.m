//
//  TICDSDropboxSDKBasedListOfPreviouslySynchronizedDocumentsOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 15/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICoreDataSync.h"


@implementation TICDSDropboxSDKBasedListOfPreviouslySynchronizedDocumentsOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)buildArrayOfDocumentIdentifiers
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self documentsDirectoryPath]];
}

- (void)fetchInfoDictionaryForDocumentWithSyncID:(NSString *)aSyncID
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadFile:[self pathToDocumentInfoForDocumentWithIdentifier:aSyncID] intoPath:[[self tempFileDirectoryPath] stringByAppendingPathComponent:aSyncID]];
}

- (void)fetchLastSynchronizationDateForDocumentWithSyncID:(NSString *)aSyncID
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self pathToDocumentRecentSyncsDirectoryForIdentifier:aSyncID]];
}

#pragma mark - Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    NSString *path = [metadata path];
    
    if( [path isEqualToString:[self documentsDirectoryPath]] ) {
        NSMutableArray *documentIdentifiers = [NSMutableArray arrayWithCapacity:[[metadata contents] count]];
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![eachSubMetadata isDirectory] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            [documentIdentifiers addObject:[[eachSubMetadata path] lastPathComponent]];
        }
        
        [self builtArrayOfDocumentIdentifiers:documentIdentifiers];
        
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSRecentSyncsDirectoryName] ) {
        
        NSString *documentIdentifier = [path stringByDeletingLastPathComponent];
        documentIdentifier = [documentIdentifier lastPathComponent];
        
        NSDate *mostRecentSyncDate = nil;
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if(  [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            if( !mostRecentSyncDate ) {
                mostRecentSyncDate = [eachSubMetadata lastModifiedDate];
                continue;
            }
            
            if( [mostRecentSyncDate compare:[eachSubMetadata lastModifiedDate]] == NSOrderedAscending ) {
                mostRecentSyncDate = [eachSubMetadata lastModifiedDate];
                continue;
            }
        }
        
        [self fetchedLastSynchronizationDate:mostRecentSyncDate forDocumentWithSyncID:documentIdentifier];
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
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [path isEqualToString:[self documentsDirectoryPath]] ) {
        [self builtArrayOfDocumentIdentifiers:nil];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSRecentSyncsDirectoryName] ) {
        
        NSString *documentIdentifier = [path stringByDeletingLastPathComponent];
        documentIdentifier = [documentIdentifier lastPathComponent];
        
        [self fetchedLastSynchronizationDate:nil forDocumentWithSyncID:documentIdentifier];
    }
}

#pragma mark Loading Files
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    NSError *anyError = nil;
    BOOL success = YES;
    
    // If we're loading files, this is for the documentInfo.plist fetch phase
    
    NSString *documentIdentifier = [destPath lastPathComponent];
    
    NSDictionary *documentInfo = nil;
    
    if( [self shouldUseEncryption] ) {
        NSString *tempFile = [destPath stringByAppendingPathExtension:@"decrypt"];
        
        success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:destPath] writingToLocation:[NSURL fileURLWithPath:tempFile] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self fetchedInfoDictionary:nil forDocumentWithSyncID:documentIdentifier];
            return;
        }
        
        documentInfo = [NSDictionary dictionaryWithContentsOfFile:tempFile];
    } else {
        documentInfo = [NSDictionary dictionaryWithContentsOfFile:destPath];
    }
    
    if( !documentInfo ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedInfoDictionary:documentInfo forDocumentWithSyncID:documentIdentifier];
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    NSString *path = [[error userInfo] valueForKey:@"path"];
    NSString *destinationPath = [[error userInfo] valueForKey:@"destinationPath"];
    NSInteger errorCode = error.code;
    
    if (errorCode == 503) { // Potentially bogus rate-limiting error code. Current advice from Dropbox is to retry immediately. --M.Fey, 2012-12-19
        TICDSLog(TICDSLogVerbosityErrorsOnly, @"Encountered an error 503, retrying immediately. %@", path);
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [client loadFile:path intoPath:destinationPath];
        return;
    }
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    [self fetchedInfoDictionary:nil forDocumentWithSyncID:[path lastPathComponent]];
}

#pragma mark - Paths
- (NSString *)pathToDocumentInfoForDocumentWithIdentifier:(NSString *)anIdentifier
{
    return [[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDocumentInfoPlistFilenameWithExtension];
}

- (NSString *)pathToDocumentRecentSyncsDirectoryForIdentifier:(NSString *)anIdentifier
{
    return [[[self documentsDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSRecentSyncsDirectoryName];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    [_restClient setDelegate:nil];

    _restClient = nil;
    _documentsDirectoryPath = nil;

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
@synthesize documentsDirectoryPath = _documentsDirectoryPath;

@end

