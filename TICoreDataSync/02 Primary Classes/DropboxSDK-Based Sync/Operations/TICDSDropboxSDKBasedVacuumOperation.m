//
//  TICDSDropboxSDKBasedVacuumOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 15/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICoreDataSync.h"


@implementation TICDSDropboxSDKBasedVacuumOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)findOutDateOfOldestWholeStore
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self thisDocumentWholeStoreDirectoryPath]];
}

- (void)findOutLeastRecentClientSyncDate
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self thisDocumentRecentSyncsDirectoryPath]];
}

- (void)removeOldSyncChangeSetFiles
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:[self thisDocumentSyncChangesThisClientDirectoryPath]];
}

#pragma mark - Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    NSString *path = [metadata path];
    
    if( [path isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![eachSubMetadata isDirectory] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            _numberOfWholeStoresToCheck++;
        }
        
        if( _numberOfWholeStoresToCheck < 1 ) {
            [self foundOutDateOfOldestWholeStoreFile:[NSDate date]];
            return;
        }
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![eachSubMetadata isDirectory] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
#if TARGET_OS_IPHONE
            [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
            [[self restClient] loadMetadata:[eachSubMetadata path]];
        }
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( [[[eachSubMetadata path] lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
                _numberOfWholeStoresChecked++;
                
                if( [eachSubMetadata isDeleted] ) {
                    continue;
                }
                
                if( ![self oldestStoreDate] ) {
                    [self setOldestStoreDate:[eachSubMetadata lastModifiedDate]];
                    continue;
                }
                
                if( [[self oldestStoreDate] compare:[eachSubMetadata lastModifiedDate]] == NSOrderedDescending ) {
                    [self setOldestStoreDate:[eachSubMetadata lastModifiedDate]];
                }
            }
        }
        
        if( _numberOfWholeStoresChecked == _numberOfWholeStoresToCheck ) {
            [self foundOutDateOfOldestWholeStoreFile:[self oldestStoreDate]];
            return;
        }
        
        if( _numberOfWholeStoresChecked + _numberOfWholeStoresThatFailedToBeChecked == _numberOfWholeStoresToCheck ) {
            [self foundOutDateOfOldestWholeStoreFile:nil];
            return;
        }
        
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentRecentSyncsDirectoryPath]] ) {
        
        NSDate *leastRecentSyncDate = nil;
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![[[eachSubMetadata path] pathExtension] isEqualToString:TICDSRecentSyncFileExtension] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            if( !leastRecentSyncDate ) {
                leastRecentSyncDate = [eachSubMetadata lastModifiedDate];
                continue;
            }
            
            if( [leastRecentSyncDate compare:[eachSubMetadata lastModifiedDate]] == NSOrderedDescending ) {
                leastRecentSyncDate = [eachSubMetadata lastModifiedDate];
                continue;
            }
        }
        
        if( !leastRecentSyncDate ) {
            leastRecentSyncDate = [NSDate date];
        }
        
        [self foundOutLeastRecentClientSyncDate:leastRecentSyncDate];
        
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( [eachSubMetadata isDeleted] || [[eachSubMetadata lastModifiedDate] compare:[self earliestDateForFilesToKeep]] == NSOrderedDescending ) {
                continue;
            }
            
            _numberOfFilesToDelete++;
        }
        
        if( _numberOfFilesToDelete < 1 ) {
            [self removedOldSyncChangeSetFilesWithSuccess:YES];
            return;
        }
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( [eachSubMetadata isDeleted] || [[eachSubMetadata lastModifiedDate] compare:[self earliestDateForFilesToKeep]] == NSOrderedDescending ) {
                continue;
            }
            
#if TARGET_OS_IPHONE
            [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
            [[self restClient] deletePath:[eachSubMetadata path]];
        }
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
    
    if( [path isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        [self foundOutDateOfOldestWholeStoreFile:nil];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        _numberOfWholeStoresThatFailedToBeChecked++;
        
        if( _numberOfWholeStoresChecked + _numberOfWholeStoresThatFailedToBeChecked == _numberOfWholeStoresToCheck ) {
            [self foundOutDateOfOldestWholeStoreFile:nil];
            return;
        }
        
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentRecentSyncsDirectoryPath]] ) {
        [self foundOutLeastRecentClientSyncDate:nil];
        return;
    }
    
    if( [path isEqualToString:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        [self removedOldSyncChangeSetFilesWithSuccess:NO];
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
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        _numberOfFilesThatFailedToBeDeleted++;
        
        if( _numberOfFilesDeleted + _numberOfFilesThatFailedToBeDeleted == _numberOfFilesToDelete ) {
            [self removedOldSyncChangeSetFilesWithSuccess:NO];
            return;
        }
    }
}

- (void)handleDeletionAtPath:(NSString *)path
{
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentSyncChangesThisClientDirectoryPath]] ) {
        _numberOfFilesDeleted++;
        
        if( _numberOfFilesDeleted == _numberOfFilesToDelete ) {
            [self removedOldSyncChangeSetFilesWithSuccess:YES];
            return;
        }
        
        if( _numberOfFilesDeleted + _numberOfFilesThatFailedToBeDeleted == _numberOfFilesToDelete ) {
            [self removedOldSyncChangeSetFilesWithSuccess:YES];
            return;
        }
        
        return;
    }
}

#pragma mark - Paths
- (NSString *)pathToWholeStoreFileForClientWithIdentifier:(NSString *)anIdentifier
{
    return [[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSWholeStoreFilename];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    [_restClient setDelegate:nil];

    _restClient = nil;
    _oldestStoreDate = nil;
    _thisDocumentWholeStoreDirectoryPath = nil;
    _thisDocumentSyncChangesThisClientDirectoryPath = nil;
    _thisDocumentRecentSyncsDirectoryPath = nil;

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
@synthesize oldestStoreDate = _oldestStoreDate;
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;
@synthesize thisDocumentRecentSyncsDirectoryPath = _thisDocumentRecentSyncsDirectoryPath;
@synthesize thisDocumentSyncChangesThisClientDirectoryPath = _thisDocumentSyncChangesThisClientDirectoryPath;

@end

