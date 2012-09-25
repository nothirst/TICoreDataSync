//
//  TICDSFileManagerBasedSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedSynchronizationOperation

- (void)fetchRemoteIntegrityKey
{
    NSString *integrityDirectoryPath = [[self thisDocumentDirectoryPath] stringByAppendingPathComponent:TICDSIntegrityKeyDirectoryName];
    
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:integrityDirectoryPath error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeSynchronizationFailedBecauseIntegrityKeyDirectoryIsMissing underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        
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
    
    [self setError:[TICDSError errorWithCode:TICDSErrorCodeSynchronizationFailedBecauseIntegrityKeyDirectoryIsMissing underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    [self fetchedRemoteIntegrityKey:nil];
}

- (void)buildArrayOfClientDeviceIdentifiers
{
    NSError *anyError = nil;
    NSArray *directoryContents = [[self fileManager] contentsOfDirectoryAtPath:[self thisDocumentSyncChangesDirectoryPath] error:&anyError];
    
    if( !directoryContents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self builtArrayOfClientDeviceIdentifiers:nil];
        return;
    }
    
    NSMutableArray *clientDeviceIdentifiers = [NSMutableArray arrayWithCapacity:[directoryContents count]];
    for( NSString *eachDirectory in directoryContents ) {
        if( [[eachDirectory substringToIndex:1] isEqualToString:@"."] ) {
            continue;
        }
        
        [clientDeviceIdentifiers addObject:eachDirectory];
    }
    
    [self builtArrayOfClientDeviceIdentifiers:clientDeviceIdentifiers];
}

- (void)uploadLocalSyncChangeSetFileAtLocation:(NSURL *)aLocation
{
    NSError *anyError = nil;
    BOOL success = YES;
    
    if( [self shouldUseEncryption] ) {
        // encrypt file first
        NSURL *tmpFileLocation = [NSURL fileURLWithPath:[[self tempFileDirectoryPath] stringByAppendingPathComponent:[[aLocation path] lastPathComponent]]];
        
        success = [[self cryptor] encryptFileAtLocation:aLocation writingToLocation:tmpFileLocation error:&anyError];
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self uploadedLocalSyncChangeSetFileSuccessfully:success];
            return;
        }
        
        aLocation = tmpFileLocation;
    }
    
    NSString *uploadPath = [[self thisDocumentSyncChangesThisClientDirectoryPath] stringByAppendingPathComponent:[[aLocation path] lastPathComponent]];
    
    success = [[self fileManager] moveItemAtPath:[aLocation path] toPath:uploadPath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self uploadedLocalSyncChangeSetFileSuccessfully:success];
}

- (void)buildArrayOfSyncChangeSetIdentifiersForClientIdentifier:(NSString *)anIdentifier
{
    NSError *anyError = nil;
    NSArray *contents = [[self fileManager] contentsOfDirectoryAtPath:[self pathToSyncChangesDirectoryForClientWithIdentifier:anIdentifier] error:&anyError];
    
    if( !contents ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    NSMutableArray *identifiers = [NSMutableArray arrayWithCapacity:[contents count]];
    for( NSString *eachIdentifier in contents ) {
        if( [[eachIdentifier substringToIndex:1] isEqualToString:@"."] ) {
            continue;
        }
        
        [identifiers addObject:[eachIdentifier stringByDeletingPathExtension]];
    }
    
    [self builtArrayOfClientSyncChangeSetIdentifiers:identifiers forClientIdentifier:anIdentifier];
}

- (void)fetchSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientIdentifier:(NSString *)aClientIdentifier toLocation:(NSURL *)aLocation
{
    NSString *remoteFileToFetch = [self pathToSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientWithIdentifier:aClientIdentifier];
    
    NSError *anyError = nil;
    
    // Get modification date first
    NSDate *modificationDate = nil;
    NSDictionary *attributes = [[self fileManager] attributesOfItemAtPath:remoteFileToFetch error:&anyError];
    if( !attributes ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self fetchedSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientIdentifier:aClientIdentifier modificationDate:modificationDate withSuccess:NO];
        return;
    }
    
    modificationDate = [attributes valueForKey:NSFileModificationDate];
    
    NSString *destinationPath = [aLocation path];
    
    // if we're encrypted, we need to copy to temporary file location first, ready for cryptor to decrypt later...
    if( [self shouldUseEncryption] ) {
        destinationPath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:[destinationPath lastPathComponent]];
    }
    
    BOOL success = [[self fileManager] copyItemAtPath:remoteFileToFetch toPath:destinationPath error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self fetchedSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientIdentifier:aClientIdentifier modificationDate:modificationDate withSuccess:success];
        return;
    }
    
    // if unencrypted, we're done
    if( ![self shouldUseEncryption] ) {
        [self fetchedSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientIdentifier:aClientIdentifier modificationDate:modificationDate withSuccess:success];
        return;
    }
    
    success = [[self cryptor] decryptFileAtLocation:[NSURL fileURLWithPath:destinationPath] writingToLocation:aLocation error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self fetchedSyncChangeSetWithIdentifier:aChangeSetIdentifier forClientIdentifier:aClientIdentifier modificationDate:modificationDate withSuccess:success];
}

- (void)uploadRecentSyncFileAtLocation:(NSURL *)aLocation
{
    NSString *remoteFile = [self thisDocumentRecentSyncsThisClientFilePath];
    
    NSError *anyError = nil;
    BOOL success = YES;
    
    if( [[self fileManager] fileExistsAtPath:remoteFile] ) {
        success = [[self fileManager] removeItemAtPath:remoteFile error:&anyError]; 
    }
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
        [self uploadedRecentSyncFileSuccessfully:success];
        return;
    }
    
    success = [[self fileManager] copyItemAtPath:[aLocation path] toPath:remoteFile error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self uploadedRecentSyncFileSuccessfully:success];
}

#pragma mark -
#pragma mark Initialization and Deallocation

#if !__has_feature(objc_arc)

 - (void)dealloc
{
    _thisDocumentDirectoryPath = nil;
    _thisDocumentSyncChangesDirectoryPath = nil;
    _thisDocumentSyncChangesThisClientDirectoryPath = nil;
    _thisDocumentRecentSyncsThisClientFilePath = nil;

}
#endif

#pragma mark -
#pragma mark Paths
- (NSString *)pathToSyncChangesDirectoryForClientWithIdentifier:(NSString *)anIdentifier
{
    return [[self thisDocumentSyncChangesDirectoryPath] stringByAppendingPathComponent:anIdentifier];
}

- (NSString *)pathToSyncChangeSetWithIdentifier:(NSString *)aChangeSetIdentifier forClientWithIdentifier:(NSString *)aClientIdentifier
{
    return [[[self pathToSyncChangesDirectoryForClientWithIdentifier:aClientIdentifier] stringByAppendingPathComponent:aChangeSetIdentifier] stringByAppendingPathExtension:TICDSSyncChangeSetFileExtension];
}

#pragma mark -
#pragma mark Properties
@synthesize thisDocumentDirectoryPath = _thisDocumentDirectoryPath;
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;
@synthesize thisDocumentSyncChangesThisClientDirectoryPath = _thisDocumentSyncChangesThisClientDirectoryPath;
@synthesize thisDocumentRecentSyncsThisClientFilePath = _thisDocumentRecentSyncsThisClientFilePath;

@end
