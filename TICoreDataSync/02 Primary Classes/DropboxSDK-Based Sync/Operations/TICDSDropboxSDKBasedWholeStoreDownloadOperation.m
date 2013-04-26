//
//  TICDSDropboxSDKBasedWholeStoreDownloadOperation.m
//  iOSNotebook
//
//  Created by Tim Isted on 14/05/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//


#import "TICoreDataSync.h"

@interface TICDSDropboxSDKBasedWholeStoreDownloadOperation ()

/** A mutable dictionary to hold the last modified dates of each client identifier's whole store. */
@property (nonatomic, strong) NSMutableDictionary *wholeStoreModifiedDates;

@end

@implementation TICDSDropboxSDKBasedWholeStoreDownloadOperation

- (BOOL)needsMainThread
{
    return YES;
}

- (void)checkForMostRecentClientWholeStore
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
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
    
    if( !identifier ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeNoPreviouslyUploadedStoreExists classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:identifier];
}

- (void)downloadWholeStoreFile
{
    NSString *storeToDownload = [self pathToWholeStoreFileForClientWithIdentifier:[self requestedWholeStoreClientIdentifier]];
    
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadFile:storeToDownload intoPath:[[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSWholeStoreFilename]];
}

- (void)downloadAppliedSyncChangeSetsFile
{
    NSString *fileToDownload = [self pathToAppliedSyncChangesFileForClientWithIdentifier:[self requestedWholeStoreClientIdentifier]];
    
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadFile:fileToDownload intoPath:[[self tempFileDirectoryPath] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename]];
}

- (void)fetchRemoteIntegrityKey
{
    NSString *directoryPath = [[self thisDocumentDirectoryPath] stringByAppendingPathComponent:TICDSIntegrityKeyDirectoryName];
    
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:YES];
#endif
    [[self restClient] loadMetadata:directoryPath];
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
        [self setWholeStoreModifiedDates:[NSMutableDictionary dictionaryWithCapacity:[[metadata contents] count]]];
        
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( ![eachSubMetadata isDirectory] || [eachSubMetadata isDeleted] ) {
                continue;
            }
            
            _numberOfWholeStoresToCheck++;
        }
        
        if( _numberOfWholeStoresToCheck < 1 ) {
            [self sortOutWhichStoreIsNewest];
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
    
    if( [[path lastPathComponent] isEqualToString:TICDSIntegrityKeyDirectoryName] ) {
        for( DBMetadata *eachSubMetadata in [metadata contents] ) {
            if( [[[eachSubMetadata path] lastPathComponent] length] < 5 ) {
                continue;
            }
            
            [self fetchedRemoteIntegrityKey:[[eachSubMetadata path] lastPathComponent]];
            return;
        }
        
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeUnexpectedOrIncompleteFileLocationOrDirectoryStructure classAndMethod:__PRETTY_FUNCTION__]];
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
    
    if( [[path lastPathComponent] isEqualToString:TICDSIntegrityKeyDirectoryName] ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeDropboxSDKRestClientError underlyingError:error classAndMethod:__PRETTY_FUNCTION__]];
        [self fetchedRemoteIntegrityKey:nil];
        return;
    }
}

#pragma mark Loading Files

- (void)restClient:(DBRestClient*)client loadProgress:(CGFloat)progress forFile:(NSString*)destPath;
{
    [self setProgress:progress];
    if( [[destPath lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {
        
        [self downloadingWholeStoreFileMadeProgress];
        return;
    }
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSAppliedSyncChangeSetsFilename] ) {
        [self downloadingAppliedSyncChangeSetsFileMadeProgress];
        return;
    }
}

- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)destPath
{
#if TARGET_OS_IPHONE
    [[UIApplication sharedApplication] ticds_setNetworkActivityIndicatorVisible:NO];
#endif

    NSError *anyError = nil;
    BOOL success = YES;
    
    if( [[destPath lastPathComponent] isEqualToString:TICDSWholeStoreFilename] ) {

        NSString *tempPath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:[[self localWholeStoreFileLocation] lastPathComponent]];

        if( [self shouldUseEncryption] ) {
            success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:destPath] writingToLocation:[NSURL fileURLWithPath:tempPath] error:&anyError];
            
            if( !success ) {
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            }
            
            destPath = tempPath;
            
        }
        
        if ( [self shouldUseCompressionForWholeStoreMoves] ) {
 
            // Rename the file with the .zip extension so that we can unzip it in place without having to manage separate temp locations
            NSString *zipFilePath = [tempPath stringByAppendingPathExtension:kSSZipArchiveFilenameSuffixForCompressedFile];
            NSString *zipDecompressPath = [zipFilePath stringByDeletingLastPathComponent];
            NSString *unzippedFilePath = [zipDecompressPath stringByAppendingPathComponent:[[self thisDocumentDirectoryPath] lastPathComponent]];
            
            success = [[self fileManager] moveItemAtPath:destPath toPath:zipFilePath error:&anyError];
            
            if (!success) {
                [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                [self downloadedWholeStoreFileWithSuccess:success];
                return;
            }

            // Unzip the file to the expected destPath location (this creates a subfolder named after the zip filename with the unzipped file within it)
            success = [SSZipArchive unzipFileAtPath:zipFilePath toDestination:zipDecompressPath overwrite:YES password:nil error:&anyError];
            
            if (!success) {
                // If the unzip fails, it may be that a pre-compression feature store was downloaded, so we'll just bypass the rest of the zip process and let the download continue normally
                
                // Reverse the renaming of the downloaded file so it is ready for the next step of the download process
                success = [[self fileManager] moveItemAtPath:zipFilePath toPath:destPath error:&anyError];

                if (!success) {
                    [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                    [self downloadedWholeStoreFileWithSuccess:success];
                    return;
                }
                
            } else {
                // The unzip was successful, so continue with the process
                
                // Remove the file from zipFilePath to clean up
                success = [[self fileManager] removeItemAtPath:zipFilePath error:&anyError];
                
                if (!success) {
                    [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                    [self downloadedWholeStoreFileWithSuccess:success];
                    return;
                }
                
                // Verify that the store now exists at the tempPath location
                success = [[self fileManager] fileExistsAtPath:unzippedFilePath];
                
                if (!success) {
                    [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
                    [self downloadedWholeStoreFileWithSuccess:success];
                    return;
                }
                
                destPath = unzippedFilePath;
            }
        }
        
        success = [[self fileManager] moveItemAtPath:destPath toPath:[[self localWholeStoreFileLocation] path] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self downloadedWholeStoreFileWithSuccess:success];
            return;
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

#pragma mark - Paths
- (NSString *)pathToWholeStoreFileForClientWithIdentifier:(NSString *)anIdentifier
{
    return [[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSWholeStoreFilename];
}

- (NSString *)pathToAppliedSyncChangesFileForClientWithIdentifier:(NSString *)anIdentifier
{
    return [[[self thisDocumentWholeStoreDirectoryPath] stringByAppendingPathComponent:anIdentifier] stringByAppendingPathComponent:TICDSAppliedSyncChangeSetsFilename];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    [_restClient setDelegate:nil];

    _restClient = nil;
    _thisDocumentDirectoryPath = nil;
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
@synthesize thisDocumentDirectoryPath = _thisDocumentDirectoryPath;
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;
@synthesize wholeStoreModifiedDates = _wholeStoreModifiedDates;

@end

