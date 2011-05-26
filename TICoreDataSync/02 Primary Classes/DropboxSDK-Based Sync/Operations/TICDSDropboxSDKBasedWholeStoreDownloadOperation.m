//
//  TICDSDropboxSDKBasedWholeStoreDownloadOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "TICoreDataSync.h"


@implementation TICDSDropboxSDKBasedWholeStoreDownloadOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)checkForMostRecentClientWholeStore
{
    [[self restClient] loadMetadata:[self thisDocumentWholeStoreDirectoryPath]];
}

- (void)sortOutWhichStoreIsNewest
{
    NSDate *mostRecentDate = nil;
    NSString *identifier = nil;
    for( NSString *eachIdentifier in [self wholeStoreModifiedDates] ) {
        NSDate *eachDate = [[self wholeStoreModifiedDates] valueForKey:eachIdentifier];
        
        if( [eachDate isKindOfClass:[NSNull class]] ) {
            continue;
        }
        
        if( !mostRecentDate ) {
            mostRecentDate = eachDate;
            identifier = eachIdentifier;
            continue;
        }
        
        if( [mostRecentDate compare:eachDate] == NSOrderedAscending ) {
            mostRecentDate = eachDate;
            identifier = eachIdentifier;
            continue;
        }
    }
    
    [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:identifier];
}

- (void)downloadWholeStoreFile
{
    NSString *storeToDownload = [self pathToWholeStoreFileForClientWithIdentifier:[self requestedWholeStoreClientIdentifier]];
    
    [[self restClient] loadFile:storeToDownload intoPath:[[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSWholeStoreFilename]];
}

- (void)downloadAppliedSyncChangeSetsFile
{
    NSString *fileToDownload = [self pathToAppliedSyncChangesFileForClientWithIdentifier:[self requestedWholeStoreClientIdentifier]];
    
    [[self restClient] loadFile:fileToDownload intoPath:[[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename]];
}

#pragma mark -
#pragma mark Rest Client Delegate
#pragma mark Metadata
- (void)restClient:(DBRestClient*)client loadedMetadata:(DBMetadata*)metadata
{
    NSString *path = [metadata path];
    
    if( [path isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        [self setWholeStoreModifiedDates:[NSMutableDictionary dictionaryWithCapacity:[[metadata contents] count]]];
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![eachSubMetadata isDirectory] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            _numberOfWholeStoresToCheck++;
        }
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![eachSubMetadata isDirectory] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            [[self restClient] loadMetadata:[eachSubMetadata path]];
        }
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        id modifiedDate = [NSNull null];
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( [[[eachSubMetadata path] lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
                modifiedDate = [eachSubMetadata lastModifiedDate];
            }
        }
        
        [[self wholeStoreModifiedDates] setValue:modifiedDate forKey:[path lastPathComponent]];
        
        if( [[self wholeStoreModifiedDates] count] < _numberOfWholeStoresToCheck ) {
            return;
        }
        
        // if we get here, we've got all the modified dates (or NSNulls)
        [self sortOutWhichStoreIsNewest];
        return;
    }
}

- (void)restClient:(DBRestClient*)client metadataUnchangedAtPath:(NSString*)path
{
    
}

- (void)restClient:(DBRestClient*)client loadMetadataFailedWithError:(NSError*)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [path isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:nil];
        return;
    }
    
    if( [[path stringByDeletingLastPathComponent] isEqualToString:[self thisDocumentWholeStoreDirectoryPath]] ) {
        [[self wholeStoreModifiedDates] setValue:[NSNull null] forKey:[path lastPathComponent]];
        
        if( [[self wholeStoreModifiedDates] count] < _numberOfWholeStoresToCheck ) {
            return;
        }
        
        // if we get here, we've got all the dates (or NSNulls)
        [self sortOutWhichStoreIsNewest];
        return;
    }
}

#pragma mark Loading Files
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        if( [self shouldUseEncryption] ) {
            success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:destPath] writingToLocation:[self localWholeStoreFileLocation] error:&anyError];
            
            if( !success ) {
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            }
        } else {
            success = [[self fileManager] moveItemAtPath:destPath toPath:[[self localWholeStoreFileLocation] path] error:&anyError];
            
            if( !success ) {
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            }
        }
        [self downloadedWholeStoreFileWithSuccess:success];
        return;
    }
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        success = [[self fileManager] moveItemAtPath:destPath toPath:[[self localAppliedSyncChangeSetsFileLocation] path] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        }
        
        [self downloadedAppliedSyncChangeSetsFileWithSuccess:success];
        return;
    }
}

- (void)restClient:(DBRestClient *)client loadFileFailedWithError:(NSError *)error
{
    NSString *path = [[error userInfo] valueForKey:@"path"];
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
    
    if( [[path lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        [self downloadedWholeStoreFileWithSuccess:NO];
        return;
    }
    
    if( [[path lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        if( [error code] == 404 ) {
            [self setError:nil];
            [self downloadedAppliedSyncChangeSetsFileWithSuccess:YES];
        } else {
            [self downloadedAppliedSyncChangeSetsFileWithSuccess:NO];
        }
        return;
    }
}

#pragma mark -
#pragma mark Paths
- (NSString *)pathToWholeStoreFileForClientWithIdentifier:(NSString *)anIdentifier
{
    return [[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSWholeStoreFilename];
}

- (NSString *)pathToAppliedSyncChangesFileForClientWithIdentifier:(NSString *)anIdentifier
{
    return [[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename];
}

#pragma mark -
#pragma mark Initialization and Deallocation
- (void)dealloc
{
    [_dbSession release], _dbSession = nil;
    [_restClient release], _restClient = nil;
    [_thisDocumentWholeStoreDirectoryPath release], _thisDocumentWholeStoreDirectoryPath = nil;

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
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;
@synthesize wholeStoreModifiedDates = _wholeStoreModifiedDates;

@end

#endif