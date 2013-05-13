//
//  TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 23/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICoreDataSync.h"


@implementation TICDSDropboxSDKBasedListOfDocumentRegisteredClientsOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)fetchArrayOfClientUUIDStrings
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self thisDocumentSyncChangesDirectoryPath]];
}

- (void)fetchDeviceInfoDictionaryForClientWithIdentifier:(NSString *)anIdentifier
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadFile:[self pathToInfoDictionaryForDeviceWithIdentifier:anIdentifier] intoPath:[[self tempFileDirectoryPath] stringByAppendingPathComponent:anIdentifier]];
}

- (void)fetchLastSynchronizationDates
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self thisDocumentRecentSyncsDirectoryPath]];
}

- (void)fetchModificationDateOfWholeStoreForClientWithIdentifier:(NSString *)anIdentifier
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self pathToWholeStoreFileForDeviceWithIdentifier:anIdentifier]];
}

#pragma mark - Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    NSString *path = [metadata path];
    
    if( [path isEqualToString:[self thisDocumentSyncChangesDirectoryPath]] ) {
        NSMutableArray *clientIdentifiers = [NSMutableArray arrayWithCapacity:[[metadata contents] count]];
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![eachSubMetadata isDirectory] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            [clientIdentifiers addObject:[[eachSubMetadata path] lastPathComponent]];
        }
        
        [self fetchedArrayOfClientUUIDStrings:clientIdentifiers];
        
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentRecentSyncsDirectoryPath]] ) {
        
        for( NSString *eachClientIdentifier in [self synchronizedClientIdentifiers] ) {
            DBMetadata *subMetadata = nil;
            for( DBMetadata *eachSubMetadata in [metadata contents] ) {
                if( [eachSubMetadata isDeleted] ) {
                    continue;
                }
                
                if( ![[[[eachSubMetadata path] lastPathComponent] stringByDeletingPathExtension] isEqualToString:eachClientIdentifier] ) {
                    continue;
                }
                
                subMetadata = eachSubMetadata;
            }
            
            [self fetchedLastSynchronizationDate:[subMetadata lastModifiedDate] forClientWithIdentifier:eachClientIdentifier];
        }
        
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        [self fetchedModificationDate:[metadata lastModifiedDate] ofWholeStoreForClientWithIdentifier:[[path stringByDeletingLastPathComponent] lastPathComponent]];
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
    
    if( [path isEqualToString:[self thisDocumentSyncChangesDirectoryPath]] ) {
        [self fetchedArrayOfClientUUIDStrings:nil ];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentRecentSyncsDirectoryPath]] ) {
        for( NSString *eachClientIdentifer in [self synchronizedClientIdentifiers] ) {
            [self fetchedLastSynchronizationDate:nil forClientWithIdentifier:eachClientIdentifer];
        }
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        [self fetchedModificationDate:nil ofWholeStoreForClientWithIdentifier:[[path stringByDeletingLastPathComponent] lastPathComponent]];
        return;
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
    
    // Only one file loaded by this operation...
    
    NSString *identifier = [destPath lastPathComponent];
    
    if( [self shouldUseEncryption] ) {
        NSString *tmpPath = [destPath stringByAppendingPathExtension:@"decrypt"];
        
        success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:destPath] writingToLocation:[NSURL fileURLWithPath:tmpPath] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self fetchedDeviceInfoDictionary:nil forClientWithIdentifier:identifier];
            return;
        }
        
        destPath = tmpPath;
    }
    
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:destPath];
    
    if( !dictionary ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedDeviceInfoDictionary:dictionary forClientWithIdentifier:identifier];
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
    
    [self fetchedDeviceInfoDictionary:nil forClientWithIdentifier:[path lastPathComponent]];
}

#pragma mark - Paths
- (NSString *)pathToInfoDictionaryForDeviceWithIdentifier:(NSString *)anIdentifier
{
    return [[[self clientDevicesDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSDeviceInfoPlistFilenameWithExtension]; 
}

- (NSString *)pathToWholeStoreFileForDeviceWithIdentifier:(NSString *)anIdentifier
{
    return [[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSWholeStoreFilename];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    [_restClient setDelegate:nil];

    _restClient = nil;
    _thisDocumentSyncChangesDirectoryPath = nil;
    _clientDevicesDirectoryPath = nil;
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
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;
@synthesize clientDevicesDirectoryPath = _clientDevicesDirectoryPath;
@synthesize thisDocumentRecentSyncsDirectoryPath = _thisDocumentRecentSyncsDirectoryPath;
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;

@end

