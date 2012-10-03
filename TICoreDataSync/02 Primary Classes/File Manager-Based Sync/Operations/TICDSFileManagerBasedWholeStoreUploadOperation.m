//
//  TICDSFileManagerBasedWholeStoreUploadOperation.m
//  ShoppingListMac
//
//  Created by Tim Isted on 25/04/2011.
//  Copyright 2011 Tim Isted. All rights reserved.
//

#import "TICoreDataSync.h"


@implementation TICDSFileManagerBasedWholeStoreUploadOperation

- (void)checkWhetherThisClientTemporaryWholeStoreDirectoryExists
{
    TICDSRemoteFileStructureExistsResponseType status = [[self fileManager] fileExistsAtPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath]] ? TICDSRemoteFileStructureExistsResponseTypeDoesExist : TICDSRemoteFileStructureExistsResponseTypeDoesNotExist;
    
    [self discoveredStatusOfThisClientTemporaryWholeStoreDirectory:status];
}

- (void)deleteThisClientTemporaryWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [[self fileManager] removeItemAtPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedThisClientTemporaryWholeStoreDirectoryWithSuccess:success];
}

- (void)createThisClientTemporaryWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [[self fileManager] createDirectoryAtPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] withIntermediateDirectories:NO attributes:nil error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self createdThisClientTemporaryWholeStoreDirectoryWithSuccess:success];
}

- (void)uploadLocalWholeStoreFileToThisClientTemporaryWholeStoreDirectory
{
    NSError *anyError = nil;
    BOOL success = YES;
    NSString *filePath = [[self localWholeStoreFileLocation] path];
    
    if( [self shouldUseEncryption] ) {
        NSString *tempPath = [[self tempFileDirectoryPath] stringByAppendingPathComponent:[filePath lastPathComponent]];
        
        success = [[self cryptor] encryptFileAtLocation:[NSURL fileURLWithPath:filePath] writingToLocation:[NSURL fileURLWithPath:tempPath] error:&anyError];
        if( !success ) {
            [self setError:[TICDSError errorWithCode:TICDSErrorCodeEncryptionError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
            [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:NO];
            return;
        }
        
        filePath = tempPath;
    }
    
    success = [[self fileManager] copyItemAtPath:filePath toPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self uploadedWholeStoreFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:success];
}

- (void)uploadLocalAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [[self fileManager] copyItemAtPath:[[self localAppliedSyncChangeSetsFileLocation] path] toPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self uploadedAppliedSyncChangeSetsFileToThisClientTemporaryWholeStoreDirectoryWithSuccess:success];
}

- (void)checkWhetherThisClientWholeStoreDirectoryExists
{
    TICDSRemoteFileStructureExistsResponseType status = [[self fileManager] fileExistsAtPath:[self thisDocumentWholeStoreThisClientDirectoryPath]] ? TICDSRemoteFileStructureExistsResponseTypeDoesExist : TICDSRemoteFileStructureExistsResponseTypeDoesNotExist;
    
    [self discoveredStatusOfThisClientWholeStoreDirectory:status];
}

- (void)deleteThisClientWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [[self fileManager] removeItemAtPath:[self thisDocumentWholeStoreThisClientDirectoryPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self deletedThisClientWholeStoreDirectoryWithSuccess:success];
}

- (void)copyThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectory
{
    NSError *anyError = nil;
    
    BOOL success = [[self fileManager] copyItemAtPath:[self thisDocumentTemporaryWholeStoreThisClientDirectoryPath] toPath:[self thisDocumentWholeStoreThisClientDirectoryPath] error:&anyError];
    
    if( !success ) {
        [self setError:[TICDSError errorWithCode:TICDSErrorCodeFileManagerError underlyingError:anyError classAndMethod:__PRETTY_FUNCTION__]];
    }
    
    [self copiedThisClientTemporaryWholeStoreDirectoryToThisClientWholeStoreDirectoryWithSuccess:success];
}

#pragma mark - Initialization and Deallocation
- (void)dealloc
{
    _thisDocumentTemporaryWholeStoreThisClientDirectoryPath = nil;
    _thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath = nil;
    _thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = nil;
    _thisDocumentWholeStoreThisClientDirectoryPath = nil;

}

#pragma mark - Properties
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryPath = _thisDocumentTemporaryWholeStoreThisClientDirectoryPath;
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath = _thisDocumentTemporaryWholeStoreThisClientDirectoryWholeStoreFilePath;
@synthesize thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath = _thisDocumentTemporaryWholeStoreThisClientDirectoryAppliedSyncChangeSetsFilePath;
@synthesize thisDocumentWholeStoreThisClientDirectoryPath = _thisDocumentWholeStoreThisClientDirectoryPath;

@end
