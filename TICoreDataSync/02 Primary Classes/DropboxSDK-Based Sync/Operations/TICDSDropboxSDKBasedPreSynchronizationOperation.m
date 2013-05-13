//
//  TICDSDropboxSDKBasedPreSynchronizationOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICoreDataSync.h"

@interface TICDSDropboxSDKBasedPreSynchronizationOperation ()

/** A dictionary used by this operation to find out the client responsible for creating a change set. */
@property (nonatomic, strong) NSMutableDictionary *clientIdentifiersForChangeSetIdentifiers;

/** A dictionary used to keep hold of the modification dates of sync change sets. */
@property (nonatomic, strong) NSMutableDictionary *changeSetModificationDates;

/** When we fail to download a changeset file we re-request it and put its path in this set so that we can keep track of the fact that we've re-requested it. */
@property (nonatomic, strong) NSMutableDictionary *failedDownloadRetryDictionary;

@end

@implementation TICDSDropboxSDKBasedPreSynchronizationOperation

#pragma mark - Overridden Methods
- (BOOL)needsMainThread
{
    return YES;
}

#pragma mark Integrity Key
- (void)fetchRemoteIntegrityKey
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    NSString *directoryPath = [[self thisDocumentDirectoryPath] stringByAppendingPathComponent:TICDSIntegrityKeyDirectoryName];
    
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:directoryPath];
}

#pragma mark Sync Change Sets
- (void)buildArrayOfClientDeviceIdentifiers
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self thisDocumentSyncChangesDirectoryPath]];
}

- (void)buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:(NSString *)anIdentifier
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self pathToSyncChangesDirectoryForClientWithIdentifier:anIdentifier]];
}

- (void)fetchSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientIdentifier:(NSString *)aClientIdentifier toLocation:(NSURL *)aLocation
{
    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    if( ![self clientIdentifiersForChangeSetIdentifiers] ) {
        [self setClientIdentifiersForChangeSetIdentifiers:[NSMutableDictionary dictionaryWithCapacity:10]];
    }
    
    [[self clientIdentifiersForChangeSetIdentifiers] setValue:aClientIdentifier forKey:aChangeSetIdentifier];
    
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadFile:[self pathToSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientWithIdentifier:aClientIdentifier] intoPath:[aLocation path]];
}

#pragma mark - Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    NSString *path = [metadata path];
    
    if( [path isEqualToString:[self thisDocumentSyncChangesDirectoryPath]] ) {
        NSMutableArray *clientDeviceIdentifiers = [NSMutableArray arrayWithCapacity:[[metadata contents] count]];
        NSString *identifier = nil;
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            identifier = [[eachSubMetadata path] lastPathComponent];
            
            if( [identifier length] < 5 || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            [clientDeviceIdentifiers addObject:identifier];
        }
        
        [self builtArrayOfClientDeviceIdentifiers:clientDeviceIdentifiers];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentSyncChangesDirectoryPath]] ) {
        if( ![self changeSetModificationDates] ) {
            [self setChangeSetModificationDates:[NSMutableDictionary dictionaryWithCapacity:20]];
        }
        
        NSMutableArray *syncChangeSetIdentifiers = [NSMutableArray arrayWithCapacity:[[metadata contents] count]];
        NSString *identifier = nil;
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            identifier = [[[eachSubMetadata path] lastPathComponent] stringByDeletingPathExtension];
            
            if( [identifier length] < 5 || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            [syncChangeSetIdentifiers addObject:identifier];
            [[self changeSetModificationDates] setValue:[eachSubMetadata lastModifiedDate] forKey:identifier];
        }
        
        [self builtArrayOfClientSyncChangeSetIdentifiers:syncChangeSetIdentifiers forClientIdentifier:[path lastPathComponent]];
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSIntegrityKeyDirectoryName] ) {
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( [[[eachSubMetadata path] lastPathComponent] length] < 5 ) {
                continue;
            }
            
            [self fetchedRemoteIntegrityKey:[[eachSubMetadata path] lastPathComponent]];
            return;
        }
        
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeSynchronizationFailedBecauseIntegrityKeyDirectoryIsMissing classAndMethod:__PRETTY_FUNCTION__]];
        [self fetchedRemoteIntegrityKey:nil];
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

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
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
        [self builtArrayOfClientDeviceIdentifiers:nil];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentSyncChangesDirectoryPath]] ) {
        [self builtArrayOfClientSyncChangeSetIdentifiers:nil forClientIdentifier:[path lastPathComponent]];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSIntegrityKeyDirectoryName] ) {
        if( [error code] == 404 ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeSynchronizationFailedBecauseIntegrityKeyDirectoryIsMissing underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
        } else {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
        }
        [self fetchedRemoteIntegrityKey:nil];
        return;
    }
}

#pragma mark Loading Files
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    NSError *anyError = nil;
    BOOL success = YES;

    if (destPath != nil) {
        [self.failedDownloadRetryDictionary removeObjectForKey:destPath];
    }

    if( [[[destPath lastPathComponent] pathExtension] isEqualToString:TICDSSyncChangeSetFileExtension] ) {
        
        NSString *changeSetIdentifier = [[destPath lastPathComponent] stringByDeletingPathExtension];
        NSString *clientIdentifier = [[self clientIdentifiersForChangeSetIdentifiers] valueForKey:changeSetIdentifier];
        
        if( [self shouldUseEncryption] ) {
            NSString *tmpPath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:[destPath lastPathComponent]];
            
            success = [[self fileManager] moveItemAtPath:destPath toPath:tmpPath error:&anyError];
            
            if( !success ) {
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                [self fetchedSyncChangeSetWithIdentifier:changeSetIdentifier forClientIdentifier:clientIdentifier modificationDate:nil withSuccess:NO];
                return;
            }
            
            success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:tmpPath] writingToLocation:[NSURL fileURLWithPath:destPath] error:&anyError];
            
            if( !success ) {
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            }
        }
        
        [self fetchedSyncChangeSetWithIdentifier:changeSetIdentifier forClientIdentifier:clientIdentifier modificationDate:[[self changeSetModificationDates] valueForKey:changeSetIdentifier] withSuccess:success];
        return;
    }
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    if (self.isCancelled) {
        [self operationWasCancelled];
        return;
    }
    
    NSString *path = [[error userInfo] valueForKey:@"path"];
    NSString *downloadDestination = [[error userInfo] valueForKey:@"destinationPath"];
    
    if (error.code != 401 && path != nil && downloadDestination != nil && [[self.failedDownloadRetryDictionary objectForKey:path] integerValue] < 5) {
        NSInteger retryCount = [[self.failedDownloadRetryDictionary objectForKey:path] integerValue];
        retryCount++;
        TICDSLog(TICDSLogVerbosityEveryStep, @"Failed to download %@. Going for try number %ld", path, (long)retryCount);
        [self.failedDownloadRetryDictionary setObject:[NSNumber numberWithInteger:retryCount] forKey:path];
#if TARGET_OS_IPHONE
        [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
        [[self restClient] loadFile:path intoPath:downloadDestination];
        return;
    }
    
    if (path != nil) {
        [self.failedDownloadRetryDictionary removeObjectForKey:path];
    }
    
    TICDSLog(TICDSLogVerbosityErrorsOnly, @"Download of %@ has failed after 5 attempts, we're falling through to the error condition.", path);

    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [[[path lastPathComponent] pathExtension] isEqualToString:TICDSSyncChangeSetFileExtension] ) {
        NSString *changeSetIdentifier = [[path lastPathComponent] stringByDeletingPathExtension];
        NSString *clientIdentifier = [[self clientIdentifiersForChangeSetIdentifiers] valueForKey:changeSetIdentifier];
        
        [self fetchedSyncChangeSetWithIdentifier:changeSetIdentifier forClientIdentifier:clientIdentifier modificationDate:nil withSuccess:NO];
        return;
    }
}

#pragma mark - Paths
- (NSString *)pathToSyncChangesDirectoryForClientWithIdentifier:(NSString *)anIdentifier
{
    return [[self thisDocumentSyncChangesDirectoryPath] stringByAppendingPathComponent:anIdentifier];
}

- (NSString *)pathToSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientWithIdentifier:(NSString *)aClientIdentifier
{
    return [[[self pathToSyncChangesDirectoryForClientWithIdentifier:aClientIdentifier] stringByAppendingPathComponent:aChangeSetIdentifier] stringByAppendingPathExtension:TICDSSyncChangeSetFileExtension];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    [_restClient setDelegate:nil];

    _restClient = nil;
    _clientIdentifiersForChangeSetIdentifiers = nil;
    _changeSetModificationDates = nil;
    _thisDocumentDirectoryPath = nil;
    _thisDocumentSyncChangesDirectoryPath = nil;
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
@synthesize clientIdentifiersForChangeSetIdentifiers = _clientIdentifiersForChangeSetIdentifiers;
@synthesize changeSetModificationDates = _changeSetModificationDates;
@synthesize thisDocumentDirectoryPath = _thisDocumentDirectoryPath;
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;
@synthesize failedDownloadRetryDictionary = _failedDownloadRetryDictionary;

@end

