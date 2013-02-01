//
//  TICDSFileManagerBasedPostSynchronizationOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 26/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedPostSynchronizationOperation

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

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _thisDocumentDirectoryPath = nil;
    _thisDocumentSyncChangesDirectoryPath = nil;
    _thisDocumentSyncChangesThisClientDirectoryPath = nil;
    _thisDocumentRecentSyncsThisClientFilePath = nil;
    
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

#pragma mark - Properties
@synthesize thisDocumentDirectoryPath = _thisDocumentDirectoryPath;
@synthesize thisDocumentSyncChangesDirectoryPath = _thisDocumentSyncChangesDirectoryPath;
@synthesize thisDocumentSyncChangesThisClientDirectoryPath = _thisDocumentSyncChangesThisClientDirectoryPath;
@synthesize thisDocumentRecentSyncsThisClientFilePath = _thisDocumentRecentSyncsThisClientFilePath;

@end
