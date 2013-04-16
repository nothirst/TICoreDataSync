//
//  TICDSiCloudBasedWholeStoreDownloadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSiCloudBasedWholeStoreDownloadOperation

- (void)checkForMostRecentClientWholeStore
{
    NSError *anyError = nil;
    NSArray *clientIdentifiers = [self contentsOfDirectoryAtPath:[self thisDocumentWholeStoreDirectoryPath] error:&anyError];
    
    if( !clientIdentifiers ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:nil];
        return;
    }
    
    NSString *identifierToReturn = nil;
    NSDate *latestModificationDate = nil;
    NSDate *eachModificationDate = nil;
    NSDictionary *attributes = nil;
    for( NSString *eachIdentifier in clientIdentifiers ) {
        if( [[eachIdentifier substringToIndex:1] isEqualToString:@"."] ) {
            continue;
        }
        
        attributes = [self attributesOfItemAtPath:[self pathToWholeStoreFileForClientWithIdentifier:eachIdentifier] error:&anyError];
        
        if( !attributes ) {
            continue;
        }
        
        eachModificationDate = [attributes valueForKey:NSFileModificationDate];
        
        if( !latestModificationDate ) {
            latestModificationDate = eachModificationDate;
            identifierToReturn = eachIdentifier;
            continue;
        } else if( [eachModificationDate compare:latestModificationDate] == NSOrderedDescending ) {
            latestModificationDate = eachModificationDate;
            identifierToReturn = eachIdentifier;
        }
    }
    
//  For some reason, this block could crash the app. The anyError seems to be the problem. Removed for now.
//    if( !identifierToReturn && anyError ) {
//        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
//        [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:nil];
//        return;
//    }
    
    if( !identifierToReturn ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeNoPreviouslyUploadedStoreExists classAndMethod:__PRETTY_FUNCTION__]];
        [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:nil];
        return;
    }
    
    [self determinedMostRecentWholeStoreWasUploadedByClientWithIdentifier:identifierToReturn];
}

- (BOOL)syncFileURL:(NSURL *)url timeout:(NSTimeInterval)timeout error:(NSError **)error
{
#if TARGET_IPHONE_SIMULATOR
    // hack to support testing on iOS Simulator
    return [[NSFileManager defaultManager] fileExistsAtPath:[url path]];
#endif
    
    NSNumber *isUbiquitousNumber;
    BOOL success = [url getResourceValue:&isUbiquitousNumber forKey:NSURLIsUbiquitousItemKey error:NULL];
    if ( !success ) return NO;
    if ( !isUbiquitousNumber.boolValue ) return YES;
    
    BOOL downloaded = NO, downloading = NO;
    NSUInteger attempt = 0;
    NSUInteger maxAttempts = timeout;
    do {
        NSNumber *downloadedNumber;
        success = [url getResourceValue:&downloadedNumber forKey:NSURLUbiquitousItemIsDownloadedKey error:error];
        if ( !success ) return NO;
        downloaded = downloadedNumber.boolValue;
        if ( downloaded ) break;
        
        NSNumber *downloadingNumber;
        success = [url getResourceValue:&downloadingNumber forKey:NSURLUbiquitousItemIsDownloadingKey error:error];
        if ( !success ) return NO;
        downloading = downloadingNumber.boolValue;
        
        if ( !downloading && attempt == 0 ) {
            BOOL success = [self.fileManager startDownloadingUbiquitousItemAtURL:url error:error];
            if ( !success ) return NO;
        }
        
        [NSThread sleepForTimeInterval:1.0];
        
        if ( ++attempt == maxAttempts ) {
            if ( error ) *error = [TICDSError errorWithCode:TICDSErrorCodeUnexpectedOrIncompleteFileLocationOrDirectoryStructure classAndMethod:__PRETTY_FUNCTION__];
            return NO;
        }
    } while ( !downloaded );
    
    return YES;
}

- (BOOL)syncDirectoryURL:(NSURL *)url error:(NSError **)error
{
#if TARGET_IPHONE_SIMULATOR
    // hack to support testing on iOS Simulator
    BOOL _dir;
    BOOL _success = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&_dir];
    return _success && _dir;
#endif
    
    NSString *path = url.path;
    NSNumber *isUbiquitousNumber;
    BOOL success = [url getResourceValue:&isUbiquitousNumber forKey:NSURLIsUbiquitousItemKey error:error];
    if ( !success ) return NO;
    if ( !isUbiquitousNumber.boolValue ) return YES;

    NSArray *subPaths = [self.fileManager contentsOfDirectoryAtPath:url.path error:error];
    if ( !subPaths ) return NO;
    
    for ( NSString *subPath in subPaths ) {        
        NSString *fullPath = [path stringByAppendingPathComponent:subPath];
        NSURL *subURL = [NSURL fileURLWithPath:fullPath];
        NSDictionary *attributes = [self.fileManager attributesOfItemAtPath:fullPath error:error];
        NSString *fileType = [attributes objectForKey:NSFileType];
                
        if ( success && [fileType isEqualToString:NSFileTypeDirectory] ) {
            success = [self syncDirectoryURL:subURL error:error];
        }
        else if ( success ) {
            success = [self syncFileURL:subURL timeout:300.0 error:error];
        }
                
        if ( !success ) return NO;
    }
    
    return YES;
}

- (void)downloadWholeStoreFile
{
    NSError *anyError = nil;
    BOOL success = YES;
    NSString *wholeStorePath = [self pathToWholeStoreFileForClientWithIdentifier:[self requestedWholeStoreClientIdentifier]];
    NSURL *storeURL = [NSURL fileURLWithPath:wholeStorePath];
    
    // Make sure the store and related files are downloaded when using iCloud
    NSDictionary *attributes = [self.fileManager attributesOfItemAtPath:storeURL.path error:&anyError];
    NSString *fileType = [attributes objectForKey:NSFileType];
    if ( [fileType isEqualToString:NSFileTypeDirectory] ) {
        success = [self syncDirectoryURL:storeURL error:&anyError];
    }
    else {
        success = [self syncFileURL:storeURL timeout:300.0 error:&anyError];
    }
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self downloadedWholeStoreFileWithSuccess:success];
        return;
    }
    
    if( ![self shouldUseEncryption] ) {
        // just copy the file straight across
        success = [self copyItemAtPath:wholeStorePath toPath:[[self localWholeStoreFileLocation] path] error:&anyError];
        
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        }
        
        [self downloadedWholeStoreFileWithSuccess:success];
        return;
    }
    
    // otherwise, copy the file to temp location, and decrypt it
    NSString *tmpStorePath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:[wholeStorePath lastPathComponent]];
    
    success = [self copyItemAtPath:wholeStorePath toPath:tmpStorePath error:&anyError];
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self downloadedWholeStoreFileWithSuccess:success];
        return;
    }
    
    success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:wholeStorePath] writingToLocation:[self localWholeStoreFileLocation] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self downloadedWholeStoreFileWithSuccess:success];
}

- (void)downloadAppliedSyncChangeSetsFile
{
    if( ![self fileExistsAtPath:[self pathToAppliedSyncChangesFileForClientWithIdentifier:[self requestedWholeStoreClientIdentifier]]] ) {
        [self downloadedAppliedSyncChangeSetsFileWithSuccess:YES];
        return;
    }
    
    NSError *anyError = nil;
    BOOL success = [self copyItemAtPath:[self pathToAppliedSyncChangesFileForClientWithIdentifier:[self requestedWholeStoreClientIdentifier]] toPath:[[self localAppliedSyncChangeSetsFileLocation] path] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self downloadedAppliedSyncChangeSetsFileWithSuccess:success];
}

- (void)fetchRemoteIntegrityKey
{
    NSString *integrityDirectoryPath = [[self thisDocumentDirectoryPath] stringByAppendingPathComponent:TICDSIntegrityKeyDirectoryName];
    
    NSError *anyError = nil;
    NSArray *contents = [self contentsOfDirectoryAtPath:integrityDirectoryPath error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self fetchedRemoteIntegrityKey:nil];
        return;
    }
    
    for( NSString *eachFile in contents ) {
        if( [eachFile length] < 5 ) {
            continue;
        }
        
        [self fetchedRemoteIntegrityKey:eachFile];
        return;
    }
    
    [self fetchedRemoteIntegrityKey:nil];
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
#pragma mark Properties
@synthesize thisDocumentDirectoryPath = _thisDocumentDirectoryPath;
@synthesize thisDocumentWholeStoreDirectoryPath = _thisDocumentWholeStoreDirectoryPath;

@end
